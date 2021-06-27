CREATE TABLE block
(
    chain_id TEXT,
    height   BIGINT,
    data     jsonb,
    time     timestamptz,
    PRIMARY KEY (chain_id, height)
);

CREATE TABLE tx
(
    hash     bytea PRIMARY KEY,
    chain_id TEXT,
    height   BIGINT,
    data     jsonb
);

CREATE TABLE tx_event
(
    tx_hash bytea,
    type TEXT,
    PRIMARY KEY (tx_hash, type)
);

CREATE INDEX tx_event_type_index ON tx_event (type);

CREATE TABLE tx_event_attr
(
    tx_hash bytea,
    type TEXT,
    key TEXT,
    value TEXT,
    PRIMARY KEY (tx_hash, type, key, value)
);

CREATE INDEX tx_event_attr_kv_index ON tx_event_attr (type, key, value);
--
-- CREATE SCHEMA workflow;
--
-- CREATE TABLE workflow.block_task
-- (
--     task       TEXT PRIMARY KEY,
--     last_block BIGINT
-- );
--
-- CREATE TABLE workflow.daily_task
-- (
--     task       TEXT PRIMARY KEY,
--     last_block BIGINT
-- );
