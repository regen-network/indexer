import logging
import os
import textwrap
from psycopg2.errors import ForeignKeyViolation
import requests
from utils import (
    is_archive_node,
    PollingProcess,
    events_to_process,
    new_events_to_process,
)

logger = logging.getLogger(__name__)


def fetch_votes_by_proposal(height, proposal_id):
    if is_archive_node():
        headers = {"x-cosmos-block-height": str(height)}
    else:
        headers = None
    # Currently EventVote only contains proposal id
    # Eventually EventVote may contain proposal id and voter address
    # At which point we could get the vote with this endpoint:
    # /cosmos/group/v1/vote_by_proposal_voter/{proposal_id}/{voter}
    # Ref: https://github.com/regen-network/indexer/pull/38#discussion_r1310958235
    resp = requests.get(
        f"{os.environ['REGEN_API']}/cosmos/group/v1/votes_by_proposal/{proposal_id}",
        headers=headers,
    )
    resp.raise_for_status()
    return resp.json()["votes"]


def gen_records(cur, query):
    cur.execute(query)
    for record in cur:
        yield record


def _index_votes(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        all_chain_nums = [
            record[0] for record in gen_records(cur, "select num from chain;")
        ]
        max_block_heights = {
            chain_num: max_block_height
            for chain_num, max_block_height in gen_records(
                cur,
                "select chain_num, MAX(block_height) from votes group by chain_num;",
            )
        }
        logger.debug(f"{all_chain_nums=}")
        logger.debug(f"{max_block_heights=}")
        for chain_num in all_chain_nums:
            if chain_num not in max_block_heights.keys():
                max_block_heights[chain_num] = 0
        logger.debug(f"{max_block_heights=}")
        for chain_num, max_block_height in max_block_heights.items():
            logger.debug(f"{chain_num=} {max_block_height=}")
            for event in new_events_to_process(
                cur, "votes", chain_num, max_block_height
            ):
                (
                    type,
                    block_height,
                    tx_idx,
                    msg_idx,
                    _,
                    _,
                    chain_num,
                    timestamp,
                    tx_hash,
                ) = event[0]
                normalize = {}
                normalize["type"] = type
                normalize["block_height"] = block_height
                normalize["tx_idx"] = tx_idx
                normalize["msg_idx"] = msg_idx
                normalize["chain_num"] = chain_num
                normalize["timestamp"] = timestamp
                normalize["tx_hash"] = tx_hash
                for entry in event:
                    (_, _, _, _, key, value, _, _, _) = entry
                    value = value.strip('"')
                    normalize[key] = value
                logger.debug(normalize)
                votes = fetch_votes_by_proposal(
                    normalize["block_height"], normalize["proposal_id"]
                )
                logger.debug(f"{votes=}")
                insert_text = textwrap.dedent(
                    """
                INSERT INTO votes (
                    type,
                    block_height,
                    tx_idx,
                    msg_idx,
                    chain_num,
                    timestamp,
                    tx_hash,
                    proposal_id,
                    voter,
                    option,
                    metadata,
                    submit_time
                ) VALUES (
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s
                ) ON CONFLICT DO NOTHING;"""
                ).strip("\n")
                with pg_conn.cursor() as _cur:
                    for vote in votes:
                        row = (
                            normalize["type"],
                            normalize["block_height"],
                            normalize["tx_idx"],
                            normalize["msg_idx"],
                            normalize["chain_num"],
                            normalize["timestamp"],
                            normalize["tx_hash"],
                            normalize["proposal_id"],
                            vote["voter"],
                            vote["option"],
                            vote["metadata"],
                            vote["submit_time"],
                        )
                        _cur.execute(
                            insert_text,
                            row,
                        )
                        logger.debug(_cur.statusmessage)
                        pg_conn.commit()
                        logger.info("vote inserted..")


def index_votes():
    p = PollingProcess(
        target=_index_votes,
        sleep_secs=1,
    )
    p.start()
