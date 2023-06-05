import base64
import hashlib
import logging
import os
import json
import re
import time
import requests
import sentry_sdk
from sentry_sdk import capture_exception
import psycopg2
from psycopg2.extensions import parse_dsn
from psycopg2.extras import Json
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=os.environ.get("LOGLEVEL", logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger()


SENTRY_DSN = os.environ.get("SENTRY_DSN")
if SENTRY_DSN:
    logger.debug("initializing sentry..")
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        # Set traces_sample_rate to 1.0 to capture 100%
        # of transactions for performance monitoring.
        # We recommend adjusting this value in production.
        traces_sample_rate=float(os.environ.get("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
        environment=os.environ.get("SENTRY_ENVIRONMENT", "development"),
    )


class SanitizedJson(Json):
    def dumps(self, obj):
        string = json.dumps(obj)
        return re.sub(r"(\\u0000)", "", string)


class BasicClient:
    def __init__(self, rpc, api):
        self.rpc = rpc
        self.api = api
        self.chain_id = self.status()["result"]["node_info"]["network"]

    def status(self):
        return requests.get(self.rpc + "/status").json()

    def earliest_block_height(self):
        return int(self.status()["result"]["sync_info"]["earliest_block_height"])

    def latest_block_height(self):
        return int(self.status()["result"]["sync_info"]["latest_block_height"])

    def get_block(self, height):
        return requests.get(self.rpc + "/block?height=" + str(height)).json()

    def get_block_txs(self, block):
        txs = block["result"]["block"]["data"]["txs"]
        txs_json = []
        for tx in txs:
            tx_bytes = base64.b64decode(tx)
            tx_hash = hashlib.sha256(tx_bytes).digest()
            tx_hash_b16 = base64.b16encode(tx_hash).decode("utf8")
            tx_json = requests.get(
                self.api + "/cosmos/tx/v1beta1/txs/" + tx_hash_b16
            ).json()
            txs_json.append({"hash": tx_hash, "tx": tx_json})
        return txs_json

    def get_tx(self, tx_hash):
        return requests.get(self.rpc + "/tx?hash=" + tx_hash).json()


def index_block(pg_conn, client: BasicClient, chain_num, height):
    block = client.get_block(height)
    block_time = block["result"]["block"]["header"]["time"]
    cur = pg_conn.cursor()
    cur.execute(
        "INSERT INTO block (chain_num, height, data, time) VALUES (%s, %s,%s,%s) ON CONFLICT DO NOTHING",
        (chain_num, height, Json(block), block_time),
    )
    txs = client.get_block_txs(block)
    logger.debug(f"{height=} {len(txs)=}")

    for tx_idx, tx in enumerate(txs):
        logger.debug(f"{chain_num=} {height=} {tx_idx=}")
        cur.execute(
            "INSERT INTO tx (chain_num, block_height, tx_idx, hash, data) VALUES (%s, %s,%s,%s,%s) ON CONFLICT DO NOTHING",
            (chain_num, height, tx_idx, tx["hash"], SanitizedJson(tx["tx"])),
        )
        logger.debug(f"number of rows affected by insert: {cur.rowcount=}")

        for msg_idx, msg in enumerate(tx["tx"]["tx"]["body"]["messages"]):
            logger.debug(f"processing {tx_idx=} {msg['@type']=} {msg_idx=}")
            try:
                # set up an isolated database transaction for the next query:
                # https://www.psycopg.org/docs/usage.html#with-statement
                # otherwise the higher-level cursor is put into a failed state
                with pg_conn:
                    with pg_conn.cursor() as _cur:
                        _cur.execute(
                            "INSERT INTO msg (chain_num, block_height, tx_idx, msg_idx, data) VALUES (%s,%s,%s,%s,%s) ON CONFLICT DO NOTHING",
                            (chain_num, height, tx_idx, msg_idx, Json(msg)),
                        )
            except psycopg2.errors.ForeignKeyViolation as exc:
                capture_exception(exc)
                logger.error(exc, exc_info=True)
            if tx["tx"]["tx_response"]["code"] == 0:
                for evt in tx["tx"]["tx_response"]["logs"][msg_idx]["events"]:
                    cur.execute(
                        "INSERT INTO msg_event (chain_num, block_height, tx_idx, msg_idx, type) VALUES (%s,%s,%s,%s,%s) "
                        "ON CONFLICT DO NOTHING",
                        (chain_num, height, tx_idx, msg_idx, evt["type"]),
                    )
                    for attr in evt["attributes"]:
                        cur.execute(
                            "INSERT INTO msg_event_attr (chain_num, block_height, tx_idx, msg_idx, type, key, value, value_hash) "
                            "VALUES (%(chain_num)s, %(height)s,%(tx_idx)s,%(msg_idx)s,%(type)s,%(key)s,%(value)s,digest(%(value)s, 'sha256')) "
                            "ON CONFLICT DO NOTHING",
                            {
                                "chain_num": chain_num,
                                "height": height,
                                "tx_idx": tx_idx,
                                "msg_idx": msg_idx,
                                "type": evt["type"],
                                "key": attr["key"],
                                "value": attr["value"],
                            },
                        )
            else:
                logger.debug(f"no events in for {msg_idx=} in {tx_idx=}...")
    pg_conn.commit()
    cur.close()


def index_blocks(pg_conn, client: BasicClient):
    cur = pg_conn.cursor()
    cur.execute("SELECT num FROM chain WHERE chain_id = %s", (client.chain_id,))
    res = cur.fetchone()
    if res is None:
        cur.execute(
            "INSERT INTO chain (chain_id) VALUES (%s) RETURNING num", (client.chain_id,)
        )
        res = cur.fetchone()
    chain_num = res[0]

    cur.execute("SELECT max(height) FROM block WHERE chain_num = %s", (chain_num,))
    res = cur.fetchone()
    cur.close()

    start_block_override = os.environ.get("START_BLOCK_OVERRIDE")
    if start_block_override:
        next_height = int(start_block_override)
        logger.warning(f"using START_BLOCK_OVERRIDE.. {next_height=}")
    elif res == (None,):
        next_height = client.earliest_block_height()
    else:
        next_height = res[0] + 1

    latest_height = client.latest_block_height()
    while True:
        while latest_height < next_height:
            time.sleep(1)
            latest_height = client.latest_block_height()
        logger.info("indexing " + client.chain_id + " block " + str(next_height))
        index_block(pg_conn, client, chain_num, next_height)
        next_height = next_height + 1


the_db = psycopg2.connect(**parse_dsn(os.environ["DATABASE_URL"]))
regen_client = BasicClient(os.environ["REGEN_RPC"], os.environ["REGEN_API"])
index_blocks(the_db, regen_client)
