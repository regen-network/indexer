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
    data     jsonb,
    foreign key (chain_id, height) REFERENCES block (chain_id, height)
);

CREATE TABLE msg
(
    tx_hash   bytea references tx,
    msg_index int,
    type      text,
    data      jsonb,
    primary key (tx_hash, msg_index)
);

CREATE TABLE msg_event
(
    tx_hash   bytea references tx,
    msg_index int,
    type      TEXT,
    foreign key (tx_hash, msg_index) references msg (tx_hash, msg_index),
    primary key (tx_hash, msg_index, type)
);

CREATE TABLE msg_event_attr
(
    tx_hash   bytea references tx,
    msg_index int,
    type      TEXT,
    key       TEXT,
    value     TEXT,
    foreign key (tx_hash, msg_index) references msg (tx_hash, msg_index),
    foreign key (tx_hash, msg_index, type) references msg_event (tx_hash, msg_index, type),
    primary key (tx_hash, msg_index, type, key, value)
);

---

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
    data     jsonb,
    foreign key (chain_id, height) REFERENCES block (chain_id, height)
);

CREATE TABLE msg
(
    id        bigserial primary key,
    tx_hash   bytea references tx,
    msg_index int,
    type      text,
    data      jsonb,
    unique (tx_hash, msg_index)
);

CREATE TABLE msg_event
(
    id     bigserial primary key,
    msg_id bigint references msg,
    type   TEXT,
    unique (msg_id, type)
);

CREATE TABLE msg_event_attr
(
    id bigserial primary key,
    event_id bigint references msg_event,
    key       TEXT,
    value     TEXT,
    unique (event_id, key, value)
);

CREATE VIEW msg_event_attr_view AS
    SELECT ea.id, ea.event_id, ea.key, ea.value FROM msg_event_attr ea
        JOIN msg m on m.tx_hash = ea.tx_hash and m.msg_index = ea.msg_index
;

---

CREATE TABLE tx_event
(
    tx_hash bytea,
    type    TEXT,
    PRIMARY KEY (tx_hash, type)
);

CREATE INDEX tx_event_type_index ON tx_event (type);

CREATE TABLE tx_event_attr
(
    tx_hash bytea,
    type    TEXT,
    key     TEXT,
    value   TEXT,
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
