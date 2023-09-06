import base64
import hashlib
from itertools import groupby
import json
import logging
import os
import re
import textwrap
import time
from multiprocessing import Process
import psycopg2
from psycopg2.extensions import parse_dsn
from psycopg2.extras import Json
import requests
from requests.exceptions import HTTPError
from sentry_sdk import capture_exception
from tenacity import retry, wait_exponential, retry_if_exception_type

logger = logging.getLogger(__name__)


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

    @retry(
        retry=retry_if_exception_type(HTTPError), wait=wait_exponential(min=4, max=60)
    )
    def get_block_txs(self, block):
        txs = block["result"]["block"]["data"]["txs"]
        txs_json = []
        for tx in txs:
            tx_bytes = base64.b64decode(tx)
            tx_hash = hashlib.sha256(tx_bytes).digest()
            tx_hash_b16 = base64.b16encode(tx_hash).decode("utf8")
            tx_resp = requests.get(self.api + "/cosmos/tx/v1beta1/txs/" + tx_hash_b16)
            tx_resp.raise_for_status()
            tx_json = tx_resp.json()
            txs_json.append({"hash": tx_hash, "tx": tx_json})
        return txs_json

    def get_tx(self, tx_hash):
        return requests.get(self.rpc + "/tx?hash=" + tx_hash).json()


class PollingProcess(Process):
    def __init__(self, **kwargs):
        self.sleep_secs = int(kwargs.pop("sleep_secs", 0))
        Process.__init__(self, **kwargs)

    def run(self):
        self.pg_conn = psycopg2.connect(**parse_dsn(os.environ["DATABASE_URL"]))
        self.client = BasicClient(os.environ["REGEN_RPC"], os.environ["REGEN_API"])
        with self.pg_conn.cursor() as cur:
            cur.execute(
                "INSERT INTO chain (chain_id) VALUES (%s) ON CONFLICT DO NOTHING",
                (self.client.chain_id,),
            )
            self.pg_conn.commit()
            cur.execute(
                "SELECT num FROM chain WHERE chain_id = %s", (self.client.chain_id,)
            )
            res = cur.fetchone()
            chain_num = res[0]
        while True:
            try:
                self._target(self.pg_conn, self.client, chain_num)
                if self.sleep_secs:
                    time.sleep(self.sleep_secs)
            except Exception as exc:
                capture_exception(exc)
                logger.error(
                    "target=%s pid=%s exc=%s",
                    self._target,
                    os.getpid(),
                    exc,
                    exc_info=True,
                )


TABLE_EVENT_NAMES_MAP = {
    "retirements": [
        "regen.ecocredit.v1.EventRetire",
        "regen.ecocredit.v1alpha1.EventRetire",
    ],
    "proposals": ["cosmos.group.v1.EventProposalPruned"],
    "class_issuers": [
        "regen.ecocredit.v1.EventCreateClass",
        "regen.ecocredit.v1.EventUpdateClassIssuers",
    ],
    "votes": ["cosmos.group.v1.EventVote"],
}


def events_to_process(cur, index_table_name):
    event_names = TABLE_EVENT_NAMES_MAP[index_table_name]
    formatted_event_names = [f"'{x}'" for x in event_names]
    formatted_event_names_set = f"({','.join(formatted_event_names)})"
    sql = textwrap.dedent(
        f"""
    SELECT mea.type,
           mea.block_height,
           mea.tx_idx,
           mea.msg_idx,
           mea.key,
           mea.value,
           mea.chain_num,
           TRIM(BOTH '"' FROM (tx.data -> 'tx_response' -> 'timestamp')::text) AS timestamp,
           encode(tx.hash, 'hex') as tx_hash
    FROM msg_event_attr AS mea
    NATURAL LEFT JOIN {index_table_name} AS e
    NATURAL LEFT JOIN tx
    WHERE mea.type IN {formatted_event_names_set} 
        AND (e.block_height IS NULL
             AND e.type IS NULL
             AND e.tx_idx IS NULL
             AND e.msg_idx IS NULL)
    ORDER BY block_height ASC,
             KEY ASC;
    """
    )
    cur.execute(sql)

    # group together results from the query above
    # the group by done based on the block_height, tx_idx, and msg_idx
    # this is how key and value are put into their own column
    for _, g in groupby(cur, lambda x: f"{x[1]}-{x[2]}-{x[3]}"):
        yield list(g)


def new_events_to_process(cur, index_table_name, chain_num, max_block_height):
    event_names = TABLE_EVENT_NAMES_MAP[index_table_name]
    formatted_event_names = [f"'{x}'" for x in event_names]
    formatted_event_names_set = f"({','.join(formatted_event_names)})"
    sql = textwrap.dedent(
        f"""
    SELECT mea.type,
           mea.block_height,
           mea.tx_idx,
           mea.msg_idx,
           mea.key,
           mea.value,
           mea.chain_num,
           TRIM(BOTH '"' FROM (tx.data -> 'tx_response' -> 'timestamp')::text) AS timestamp,
           encode(tx.hash, 'hex') as tx_hash
    FROM msg_event_attr AS mea
    NATURAL LEFT JOIN {index_table_name} AS e
    NATURAL LEFT JOIN tx
    WHERE mea.type IN {formatted_event_names_set} 
        AND (e.block_height IS NULL
             AND e.type IS NULL
             AND e.tx_idx IS NULL
             AND e.msg_idx IS NULL)
        AND mea.chain_num = {chain_num}
        AND mea.block_height > {max_block_height}
    ORDER BY block_height ASC,
             KEY ASC;
    """
    )
    cur.execute(sql)

    # group together results from the query above
    # the group by done based on the block_height, tx_idx, and msg_idx
    # this is how key and value are put into their own column
    for _, g in groupby(cur, lambda x: f"{x[1]}-{x[2]}-{x[3]}"):
        yield list(g)


def is_archive_node():
    # since the indexer is intended to run against archive nodes,
    # assume that by default the node is an archive node.
    value = os.environ.get("REGEN_IS_ARCHIVE_NODE", "true").lower()
    if value not in ["true", "false"]:
        raise ValueError("REGEN_IS_ARCHIVE_NODE must be true or false")
    return value == "true"
