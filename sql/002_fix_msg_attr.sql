ALTER TABLE msg_event_attr ADD COLUMN value_hash bytea;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

UPDATE msg_event_attr SET value_hash = digest(value, 'sha256') WHERE TRUE;

ALTER TABLE msg_event_attr DROP CONSTRAINT msg_event_attr_pkey;

ALTER TABLE msg_event_attr ADD PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, type, key, value_hash);
