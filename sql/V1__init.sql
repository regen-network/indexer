CREATE SCHEMA "regen-1";

CREATE TABLE "regen-1".block
(
    height BIGINT primary key,
    data   jsonb,
    time   timestamptz
);

CREATE TABLE "regen-1".tx
(
    block_height bigint references "regen-1".block,
    tx_idx       smallint,
    hash         bytea unique,
    data         jsonb,
    primary key (block_height, tx_idx)
);

CREATE TABLE "regen-1".msg
(
    block_height bigint,
    tx_idx       smallint,
    msg_idx      smallint,
    data         jsonb,
    primary key (block_height, tx_idx, msg_idx),
    foreign key (block_height, tx_idx) references "regen-1".tx (block_height, tx_idx)
);

CREATE INDEX ON "regen-1".msg USING GIN ((data -> '@type'));

CREATE TABLE "regen-1".msg_event
(
    block_height bigint,
    tx_idx       smallint,
    msg_idx      smallint,
    type         TEXT,
    primary key (block_height, tx_idx, msg_idx, type),
    foreign key (block_height, tx_idx, msg_idx) references "regen-1".msg (block_height, tx_idx, msg_idx)
);

CREATE TABLE "regen-1".msg_event_attr
(
    block_height bigint,
    tx_idx       smallint,
    msg_idx      smallint,
    type         TEXT,
    key          text,
    value        text,
    primary key (block_height, tx_idx, msg_idx, type, key, value),
    foreign key (block_height, tx_idx, msg_idx) references "regen-1".msg (block_height, tx_idx, msg_idx)
);