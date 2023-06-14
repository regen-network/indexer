import logging
from utils import PollingProcess, events_to_process

logger = logging.getLogger(__name__)


def _index_retires(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(
            cur,
            "retirements",
        ):
            (type, block_height, tx_idx, msg_idx, _, _, chain_num) = event[0]
            normalize = {}
            normalize["type"] = type
            normalize["block_height"] = block_height
            normalize["tx_idx"] = tx_idx
            normalize["msg_idx"] = msg_idx
            normalize["chain_num"] = chain_num
            for entry in event:
                (_, _, _, _, key, value, _) = entry
                value = value.strip('"')
                if "v1alpha1.EventRetire" in entry[0]:
                    if key == "amount":
                        normalize["amount"] = value
                    elif key == "batch_denom":
                        normalize["batch_denom"] = value
                    elif key == "location":
                        normalize["jurisdiction"] = value
                    elif key == "retirer":
                        normalize["owner"] = value
                elif "v1.EventRetire" in entry[0]:
                    normalize[key] = value
                if "reason" not in normalize:
                    normalize["reason"] = ""
            retirement = (
                normalize["type"],
                normalize["amount"],
                normalize["batch_denom"],
                normalize["jurisdiction"],
                normalize["owner"],
                normalize["reason"],
                normalize["block_height"],
                normalize["chain_num"],
                normalize["tx_idx"],
                normalize["msg_idx"],
            )
            with pg_conn.cursor() as _cur:
                _cur.execute(
                    "INSERT INTO retirements (type, amount, batch_denom, jurisdiction, owner, reason, block_height, chain_num, tx_idx, msg_idx) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                    retirement,
                )
                logger.info("retirement inserted...")
                pg_conn.commit()


def index_retires():
    p = PollingProcess(
        target=_index_retires,
        sleep_secs=1,
    )
    p.start()
