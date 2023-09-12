import logging
import os
import textwrap
import requests
from utils import is_archive_node, PollingProcess, events_to_process

logger = logging.getLogger(__name__)


def fetch_class_issuers(height, class_id):
    if is_archive_node():
        headers = {"x-cosmos-block-height": str(height)}
    else:
        headers = None
    resp = requests.get(
        f"{os.environ['REGEN_API']}/regen/ecocredit/v1/classes/{class_id}/issuers",
        headers=headers,
    )
    resp.raise_for_status()
    return resp.json()["issuers"]


def _index_class_issuers(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(
            cur,
            "class_issuers",
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
            logger.info(normalize)
            issuers = fetch_class_issuers(
                normalize["block_height"], normalize["class_id"]
            )
            logger.info(normalize)
            logger.info(issuers)
            insert_text = textwrap.dedent(
                """
            INSERT INTO class_issuers (
                type,
                block_height,
                tx_idx,
                msg_idx,
                chain_num,
                timestamp,
                tx_hash,
                class_id,
                issuer
            ) VALUES (
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
                _cur.execute(
                    "UPDATE class_issuers SET latest='f' WHERE class_id = %s;",
                    (normalize["class_id"],),
                )
                logger.info(_cur.statusmessage)
                for issuer in issuers:
                    row = (
                        normalize["type"],
                        normalize["block_height"],
                        normalize["tx_idx"],
                        normalize["msg_idx"],
                        normalize["chain_num"],
                        normalize["timestamp"],
                        normalize["tx_hash"],
                        normalize["class_id"],
                        issuer,
                    )
                    _cur.execute(
                        insert_text,
                        row,
                    )
                    logger.info(_cur.statusmessage)
                pg_conn.commit()
                logger.info("credit class issuers updated..")


def index_class_issuers():
    p = PollingProcess(
        target=_index_class_issuers,
        sleep_secs=1,
    )
    p.start()
