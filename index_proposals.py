import logging
import os
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
    return resp.json()


def _index_proposals(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(
            cur,
            "proposals",
        ):
            (type, block_height, tx_idx, msg_idx, _, _, chain_num, timestamp) = event[0]
            normalize = {}
            normalize["type"] = type
            normalize["block_height"] = block_height
            normalize["tx_idx"] = tx_idx
            normalize["msg_idx"] = msg_idx
            normalize["chain_num"] = chain_num
            normalize["timestamp"] = timestamp
            for entry in event:
                (_, _, _, _, key, value, _, _) = entry
                value = value.strip('"')
                normalize[key] = value
            normalize["metadata"] = fetch_proposal(
                normalize["block_height"] - 1, normalize["proposal_id"]
            )
            with pg_conn.cursor() as _cur:
                row = (
                    normalize["type"],
                    normalize["proposal_id"],
                    normalize["status"],
                    normalize["tally_result"],
                    normalize["timestamp"],
                    normalize["block_height"],
                    normalize["chain_num"],
                    normalize["tx_idx"],
                    normalize["msg_idx"],
                    Json(normalize["metadata"]),
                )
                _cur.execute(
                    "INSERT INTO proposals (type, proposal_id, status, tally_result, timestamp, block_height, chain_num, tx_idx, msg_idx, metadata) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
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
