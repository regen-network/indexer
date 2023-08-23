import logging
import os
import textwrap
from psycopg2.errors import ForeignKeyViolation
import requests
from utils import PollingProcess, events_to_process

logger = logging.getLogger(__name__)


def fetch_votes_by_proposal(height, proposal_id):
    resp = requests.get(
        f"{os.environ['REGEN_API']}/cosmos/group/v1/votes_by_proposal/{proposal_id}",
        headers={"x-cosmos-block-height": str(height)},
    )
    resp.raise_for_status()
    return resp.json()["votes"]


def _index_votes(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(
            cur,
            "votes",
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
            logger.debug(votes)
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
            );"""
            ).strip("\n")
            with pg_conn.cursor() as _cur:
                for vote in votes:
                    try:
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
                    except ForeignKeyViolation as exc:
                        logger.debug(exc)
                        pg_conn.rollback()


def index_votes():
    p = PollingProcess(
        target=_index_votes,
        sleep_secs=1,
    )
    p.start()
