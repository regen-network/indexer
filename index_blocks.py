import logging
import os
import time
import psycopg2
from psycopg2.extras import Json
from sentry_sdk import capture_exception
from utils import SanitizedJson, BasicClient, PollingProcess


logger = logging.getLogger(__name__)


def index_block(pg_conn, client: BasicClient, chain_num, height):
    block = client.get_block(height)
    block_time = block["result"]["block"]["header"]["time"]
    cur = pg_conn.cursor()
    cur.execute(
        "INSERT INTO block (chain_num, height, data, time) VALUES (%s, %s,%s,%s) ON CONFLICT DO NOTHING",
        (chain_num, height, Json(block), block_time),
    )
    txs = client.get_block_txs(block)
    logger.info(f"{height=} {len(txs)=}")

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
            except psycopg2.errors.ForeignKeyViolation as exc:
                capture_exception(exc)
                logger.error(exc, exc_info=True)
    pg_conn.commit()
    cur.close()


def _index_blocks(pg_conn, client: BasicClient, chain_num):

    if os.environ.get("ONLY_INDEX_SPECIFIC_BLOCKS"):
        # this environment variable overrides the indexing process to only index specific blocks
        # the blocks that will be indexed must be in a single-column plain text file
        # each row in the file is the block height that we want indexed
        # this is useful for local development of the indexer when you are interested in specific blocks
        with open("blocks.txt", "r") as fp:
            blocks = [int(x.strip()) for x in fp.readlines()]
        for block in blocks:
            index_block(pg_conn, client, chain_num, block)
        return None

    with pg_conn.cursor() as cur:
        cur.execute("SELECT max(height) FROM block WHERE chain_num = %s", (chain_num,))
        res = cur.fetchone()
        cur.close()

    if res == (None,):
        next_height = client.earliest_block_height()
    else:
        next_height = res[0] + 1

    latest_height = client.latest_block_height()
    if latest_height < next_height:
        time.sleep(1)
    else:
        logger.info("indexing " + client.chain_id + " block " + str(next_height))
        index_block(pg_conn, client, chain_num, next_height)
        next_height = next_height + 1


def index_blocks():
    p = PollingProcess(
        target=_index_blocks,
    )
    p.start()
