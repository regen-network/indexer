import logging
import os
import textwrap
import requests
from utils import PollingProcess, events_to_process, new_events_to_process
from collections import defaultdict

logger = logging.getLogger(__name__)


def fetch_sell_order(height, sell_order_id):
    resp = requests.get(
        f"{os.environ['REGEN_API']}/regen/ecocredit/marketplace/v1/sell-orders/{sell_order_id}",
        headers={"x-cosmos-block-height": str(height)},
    )
    resp.raise_for_status()
    return resp.json()["sell_order"]

def fetch_project_id(batch_denom):
    resp = requests.get(
        f"{os.environ['REGEN_API']}/regen/ecocredit/v1/batches/{batch_denom}"
    )
    resp.raise_for_status()
    batch = resp.json()["batch"]
    return batch["project_id"]


def _index_orders(pg_conn, _client, _chain_num):
    with pg_conn.cursor() as cur:
        for event in new_events_to_process(
            cur,
            "orders",
            _chain_num,
            18054990
        ):
            # Dictionary to store events grouped by project_id and ask_denom
            events_by_project_and_denom = defaultdict(lambda: defaultdict(list))
            (type, block_height, tx_idx, msg_idx, _, _, chain_num, timestamp, tx_hash) = event[0]

            # We need to get the corresponding msg.data
            # because EventBuyDirect only stores sell order id currently
            sql = textwrap.dedent(
                f"""
            SELECT data
            FROM msg
            WHERE chain_num = {chain_num} AND block_height = {block_height} AND tx_idx = {tx_idx} AND msg_idx = {msg_idx}
            """
            )
            cur.execute(sql)
            res = cur.fetchone()
            data = res[0]

            normalize = {}
            normalize["type"] = type
            normalize["block_height"] = block_height
            normalize["tx_idx"] = tx_idx
            normalize["msg_idx"] = msg_idx
            normalize["chain_num"] = chain_num
            normalize["timestamp"] = timestamp
            normalize["tx_hash"] = tx_hash
            normalize["buyer_address"] = data["buyer"]

            for order in data["orders"]:
                # If all credits have been purchased in the sell order, then it's pruned from state,
                # so we need to retrieve the sell order info at height - 1 to get the corresponding project_id
                sell_order = fetch_sell_order(
                    normalize["block_height"] - 1, order["sell_order_id"]
                )
                project_id = fetch_project_id(sell_order["batch_denom"])
                ask_denom = sell_order["ask_denom"]
                # We group by project_id and ask_denom so we insert a new row in orders table by (project_id, ask_denom)
                events_by_project_and_denom[project_id][ask_denom].append(order)
            
            for project_id, denoms in events_by_project_and_denom.items():
                for ask_denom, orders in denoms.items():
                    normalize["credits_amount"] = 0
                    normalize["total_price"] = 0

                    for order in orders:
                        normalize["credits_amount"] = normalize["credits_amount"] + float(order["quantity"])
                        normalize["total_price"] = normalize["total_price"] + float(order["bid_price"]["amount"]) * float(order["quantity"])
                        normalize["ask_denom"] = order["bid_price"]["denom"]
                        normalize["retired_credits"] = not order["disable_auto_retire"]
                    row = (
                        normalize["type"],
                        normalize["block_height"],
                        normalize["tx_idx"],
                        normalize["msg_idx"],
                        normalize["chain_num"],
                        normalize["timestamp"],
                        normalize["tx_hash"],
                        normalize["buyer_address"],
                        normalize["credits_amount"],
                        normalize["total_price"],
                        normalize["ask_denom"],
                        normalize["retired_credits"],
                        order["retirement_reason"],
                        order["retirement_jurisdiction"],
                        project_id,
                    )
                    insert_text = textwrap.dedent("""
                    INSERT INTO orders (
                        type,
                        block_height,
                        tx_idx,
                        msg_idx,
                        chain_num,
                        timestamp,
                        tx_hash,
                        buyer_address,
                        credits_amount,
                        total_price,
                        ask_denom,
                        retired_credits,
                        retirement_reason,
                        retirement_jurisdiction,
                        project_id
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
                        %s
                    );""").strip("\n")
                    with pg_conn.cursor() as _cur:
                        _cur.execute(
                            insert_text,
                            row,
                        )
                        logger.debug(_cur.statusmessage)
                        pg_conn.commit()
                        logger.info("order inserted...")


def index_orders():
    p = PollingProcess(
        target=_index_orders,
        sleep_secs=1,
    )
    p.start()
