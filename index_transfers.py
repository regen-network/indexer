import logging
import textwrap
from utils import PollingProcess, events_to_process

logger = logging.getLogger(__name__)

V1_MSG_SEND = "/regen.ecocredit.v1.MsgSend"


def _float(v):
    # Event attrs come through quoted; tradable/retired can be "".
    try:
        return float(v) if v else 0.0
    except Exception:
        return 0.0


def _get_msg_type(cur, chain_num, block_height, tx_idx, msg_idx):
    cur.execute(
        """
        SELECT data->>'@type'
        FROM msg
        WHERE chain_num=%s AND block_height=%s AND tx_idx=%s AND msg_idx=%s
        """,
        (chain_num, block_height, tx_idx, msg_idx),
    )
    row = cur.fetchone()
    return row[0] if row else None


def _index_transfers(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in events_to_process(cur, "transfers"):
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

            # Filter to MsgSend (defensive: EventTransfer can be emitted by other ecocredit messages)
            msg_type = _get_msg_type(cur, chain_num, block_height, tx_idx, msg_idx)
            if msg_type != V1_MSG_SEND:
                continue

            normalize = {}
            normalize["type"] = type
            normalize["block_height"] = block_height
            normalize["tx_idx"] = tx_idx
            normalize["msg_idx"] = msg_idx
            normalize["chain_num"] = chain_num
            normalize["timestamp"] = timestamp
            normalize["tx_hash"] = tx_hash
            normalize["batch_denom"] = None
            normalize["tradable_amount"] = 0.0
            normalize["retired_amount"] = 0.0
            normalize["sender"] = None
            normalize["recipient"] = None

            for entry in event:
                (_, _, _, _, key, value, _, _, _) = entry
                value = value.strip('"')
                if key == "sender":
                    normalize["sender"] = value
                elif key == "recipient":
                    normalize["recipient"] = value
                elif key == "batch_denom":
                    normalize["batch_denom"] = value
                elif key == "tradable_amount":
                    normalize["tradable_amount"] = normalize["tradable_amount"] + _float(value)
                elif key == "retired_amount":
                    normalize["retired_amount"] = normalize["retired_amount"] + _float(value)

            # Required fields (table columns are NOT NULL)
            if not (normalize["batch_denom"] and normalize["sender"] and normalize["recipient"]):
                logger.warning(
                    "skipping transfer with missing fields tx_hash=%s height=%s tx_idx=%s msg_idx=%s batch=%r sender=%r recipient=%r",
                    tx_hash,
                    block_height,
                    tx_idx,
                    msg_idx,
                    normalize["batch_denom"],
                    normalize["sender"],
                    normalize["recipient"],
                )
                continue

            insert_statement = textwrap.dedent(
                """
                INSERT INTO transfers (
                    type,
                    tradable_amount,
                    retired_amount,
                    batch_denom,
                    sender,
                    recipient,
                    "timestamp",
                    block_height,
                    chain_num,
                    tx_idx,
                    msg_idx,
                    tx_hash
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                ) ON CONFLICT DO NOTHING;
                """
            ).strip("\n")

            transfer = (
                normalize["type"],
                "{:.18g}".format(normalize["tradable_amount"]),
                "{:.18g}".format(normalize["retired_amount"]),
                normalize["batch_denom"],
                normalize["sender"],
                normalize["recipient"],
                normalize["timestamp"],
                normalize["block_height"],
                normalize["chain_num"],
                normalize["tx_idx"],
                normalize["msg_idx"],
                normalize["tx_hash"],
            )

            cur.execute(insert_statement, transfer)
            pg_conn.commit()
            logger.info("transfer inserted...")


def index_transfers():
    p = PollingProcess(
        target=_index_transfers,
        sleep_secs=1,
    )
    p.start()