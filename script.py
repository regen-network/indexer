import logging
import os
from itertools import groupby
import psycopg2
from psycopg2.extensions import parse_dsn
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=os.environ.get("LOGLEVEL", logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger()


def index_blocks(pg_conn):
    with pg_conn.cursor() as cur:
        # NOTE: this query **is generalizable** into a function with two parameters
        EVENT_IDENTIFIER = "EventRetire"
        EVENT_INDEX_TABLE = "retirements"
        # this sql query finds all the matching events that have not been indexed
        sql = f"""
        SELECT type,
               block_height,
               tx_idx,
               msg_idx,
               key,
               value
        FROM msg_event_attr
        WHERE TYPE like '%{EVENT_IDENTIFIER}'
            AND (block_height,
                 type,
                 tx_idx,
                 msg_idx) NOT IN
                (SELECT block_height,
                        type,
                        tx_idx,
                        msg_idx
                 FROM {EVENT_INDEX_TABLE})
        ORDER BY block_height ASC,
                 KEY ASC;
        """
        cur.execute(sql)

        # NOTE: this groupby operation **is generalized** (and not specific to Event Type)
        groups = []
        # group together results from the query above
        # the group by done based on the block_height, tx_idx, and msg_idx
        # this is how key and value are put into their own column
        for _, g in groupby(cur, lambda x: f"{x[1]}-{x[2]}-{x[3]}"):
            groups.append(list(g))

        # NOTE: this **normalization process is not generalizable** and will be unique to each event
        retirements = []
        for g in groups:
            (type, block_height, tx_idx, msg_idx, _, _, chain_num) = g[0]
            normalize = {}
            normalize["type"] = type
            normalize["block_height"] = block_height
            normalize["tx_idx"] = tx_idx
            normalize["msg_idx"] = msg_idx
            normalize["chain_num"] = chain_num
            for entry in g:
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
            retirements.append(retirement)

        cur.executemany(
            "INSERT INTO retirements (type, amount, batch_denom, jurisdiction, owner, reason, block_height, chain_num, tx_idx, msg_idx) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            retirements,
        )
        pg_conn.commit()


if __name__ == "__main__":
    pg_conn = psycopg2.connect(**parse_dsn(os.environ["DATABASE_URL"]))
    index_blocks(pg_conn)
