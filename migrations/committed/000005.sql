--! Previous: sha1:8aa6f840171d1c0076e70fbee8dd9b56f794a03d
--! Hash: sha1:fc876ad23b772a75c10056c5b7165585c454983d

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
  "timestamp" timestamp with time zone,
  type text NOT NULL,
  credits_amount text NOT NULL,
  project_id text NOT NULL,
  buyer_address text NOT NULL,
  total_price text NOT NULL,
  ask_denom text NOT NULL,
  retired_credits BOOLEAN NOT NULL,
  retirement_reason text,
  retirement_jurisdiction text,
  block_height bigint NOT NULL,
  chain_num smallint NOT NULL,
  tx_idx smallint NOT NULL,
  msg_idx smallint NOT NULL,
  tx_hash text NOT NULL,
  PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, project_id, ask_denom)
);

DROP INDEX IF EXISTS orders_buyer_address_idx;
CREATE INDEX orders_buyer_address_idx ON orders USING btree (buyer_address);
