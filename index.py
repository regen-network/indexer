import base64
import hashlib
import os
import time

import requests
import psycopg2
from psycopg2.extensions import parse_dsn
from psycopg2.extras import Json
from dotenv import load_dotenv

load_dotenv()


class BasicClient:
    def __init__(self, rpc, api):
        self.rpc = rpc
        self.api = api
        self.chain_id = self.status()['result']['node_info']['network']

    def status(self):
        return requests.get(self.rpc + '/status').json()

    def earliest_block_height(self):
        return int(self.status()['result']['sync_info']['earliest_block_height'])

    def latest_block_height(self):
        return int(self.status()['result']['sync_info']['latest_block_height'])

    def get_block(self, height):
        return requests.get(self.rpc + '/block?height=' + str(height)).json()

    def get_block_txs(self, block):
        txs = block['result']['block']['data']['txs']
        txs_json = []
        for tx in txs:
            tx_bytes = base64.b64decode(tx)
            tx_hash = base64.b16encode(hashlib.sha256(tx_bytes).digest()).decode('utf8')
            tx_json = requests.get(self.api + '/cosmos/tx/v1beta1/txs/' + tx_hash).json()
            txs_json.append({"hash": tx_hash, "tx": tx_json})
        return txs_json

    def get_tx(self, tx_hash):
        return requests.get(self.rpc + '/tx?hash=' + tx_hash).json()


def extract_events(tx):
    logs = tx['tx_response']['logs']
    events = []
    for log in logs:
        events = events + log['events']
    return events


regen_client = BasicClient(os.environ['REGEN_RPC'], os.environ['REGEN_API'])


# print(regen_client.get_block(100))
# txs = regen_client.get_block_txs(regen_client.get_block(100))
# print(extract_events(txs[0]))


def connect_db():
    return psycopg2.connect(**parse_dsn(os.environ['DATABASE']))


test_db = connect_db()


def index_block(pg_conn, client: BasicClient, height):
    block = client.get_block(height)
    time = block['result']['block']['header']['time']
    cur = pg_conn.cursor()
    cur.execute("INSERT INTO block (chain_id, height, data, time) VALUES (%s,%s,%s,%s) ON CONFLICT DO NOTHING",
                (client.chain_id, height, Json(block), time))
    txs = client.get_block_txs(block)
    for tx in txs:
        cur.execute("INSERT INTO tx (hash, chain_id, height, data) VALUES (%s,%s,%s,%s) ON CONFLICT DO NOTHING",
                    (tx['hash'], client.chain_id, height, Json(tx['tx']))),
        events = extract_events(tx['tx'])
        for evt in events:
            cur.execute("INSERT INTO tx_event (tx_hash, type) VALUES (%s,%s) ON CONFLICT DO NOTHING",
                        (tx['hash'], evt['type']))
            for attr in evt['attributes']:
                cur.execute("INSERT INTO tx_event_attr (tx_hash, type, key, value) VALUES (%s,%s,%s,%s) ON CONFLICT "
                            "DO NOTHING",
                            (tx['hash'], evt['type'], attr['key'], attr['value']))
    pg_conn.commit()
    cur.close()


def index_blocks(pg_conn, client: BasicClient):
    cur = pg_conn.cursor()
    cur.execute("SELECT max(height) FROM block WHERE chain_id = %s", (client.chain_id,))
    res = cur.fetchone()
    cur.close()
    if res == (None,):
        next_height = client.earliest_block_height()
    else:
        next_height = res[0] + 1
    latest_height = client.latest_block_height()
    while True:
        while latest_height < next_height:
            time.sleep(1)
            latest_height = client.latest_block_height()
        print('indexing ' + client.chain_id + ' block ' + str(next_height))
        index_block(pg_conn, client, next_height)
        next_height = next_height + 1


index_blocks(test_db, regen_client)