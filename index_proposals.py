import logging
import os
import textwrap
from psycopg2.extras import Json
import requests
from utils import PollingProcess, events_to_process

logger = logging.getLogger(__name__)


def fetch_proposal(height, proposal_id):
    resp = requests.get(
        f"{os.environ['REGEN_API']}/cosmos/group/v1/proposal/{proposal_id}",
        headers={"x-cosmos-block-height": str(height)},
    )
    resp.raise_for_status()
    return resp.json()["proposal"]


def _index_proposals(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(
            cur,
            "proposals",
        ):
            (type, block_height, tx_idx, msg_idx, _, _, chain_num, timestamp, tx_hash) = event[0]
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
            proposal = fetch_proposal(
                normalize["block_height"] - 1, normalize["proposal_id"]
            )
            row = (
                normalize["type"],
                normalize["block_height"],
                normalize["tx_idx"],
                normalize["msg_idx"],
                normalize["chain_num"],
                normalize["timestamp"],
                normalize["tx_hash"],
                proposal["id"],
                proposal["status"],
                proposal["group_policy_address"],
                proposal["metadata"],
                proposal["proposers"],
                proposal["submit_time"],
                proposal["group_version"],
                proposal["group_policy_version"],
                Json(proposal["final_tally_result"]),
                proposal["voting_period_end"],
                proposal["executor_result"],
                Json(proposal["messages"]),
            )
            insert_text = textwrap.dedent("""
            INSERT INTO proposals (
                type,
                block_height,
                tx_idx,
                msg_idx,
                chain_num,
                timestamp,
                tx_hash,
                proposal_id,
                status,
                group_policy_address,
                metadata,
                proposers,
                submit_time,
                group_version,
                group_policy_version,
                final_tally_result,
                voting_period_end,
                executor_result,
                messages
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
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s
            );""").strip("\n")
            with pg_conn.cursor() as _cur:
                _cur.execute(
                    insert_text,
                    row,
                )
                logger.debug(_cur.statusmessage)
                pg_conn.commit()
                logger.info("proposal inserted...")


def index_proposals():
    p = PollingProcess(
        target=_index_proposals,
        sleep_secs=1,
    )
    p.start()
