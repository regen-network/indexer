CREATE TABLE chain
(
    num      smallserial primary key,
    chain_id text not null unique
);

CREATE TABLE block
(
    chain_num smallint    not null references chain,
    height    BIGINT      not null,
    data      jsonb       not null,
    time      timestamptz not null,
    primary key (chain_num, height)
);

CREATE TABLE tx
(
    chain_num    smallint     not null,
    block_height bigint       not null,
    tx_idx       smallint     not null,
    hash         bytea unique not null,
    data         jsonb        not null,
    primary key (chain_num, block_height, tx_idx),
    foreign key (chain_num, block_height) references block
);

CREATE TABLE msg
(
    chain_num    smallint not null,
    block_height bigint   not null,
    tx_idx       smallint not null,
    msg_idx      smallint not null,
    data         jsonb    not null,
    primary key (chain_num, block_height, tx_idx, msg_idx),
    foreign key (chain_num, block_height, tx_idx) references tx
);

CREATE INDEX ON msg USING GIN ((data -> '@type'));

CREATE TABLE msg_event
(
    chain_num    smallint not null,
    block_height bigint   not null,
    tx_idx       smallint not null,
    msg_idx      smallint not null,
    type         TEXT     not null,
    primary key (chain_num, block_height, tx_idx, msg_idx, type),
    foreign key (chain_num, block_height, tx_idx, msg_idx) references msg
);

CREATE TABLE msg_event_attr
(
    chain_num    smallint not null,
    block_height bigint   not null,
    tx_idx       smallint not null,
    msg_idx      smallint not null,
    type         TEXT     not null,
    key          text     not null,
    value        text     not null,
    primary key (chain_num, block_height, tx_idx, msg_idx, type, key, value),
    foreign key (chain_num, block_height, tx_idx, msg_idx) references msg
);
