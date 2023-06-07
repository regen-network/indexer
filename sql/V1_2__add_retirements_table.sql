CREATE TABLE IF NOT EXISTS
  retirements (
    TYPE TEXT NOT NULL,
    amount TEXT NOT NULL,
    batch_denom TEXT NOT NULL,
    jurisdiction TEXT NOT NULL,
    OWNER TEXT NOT NULL,
    reason TEXT NOT NULL,
    block_height BIGINT NOT NULL,
    chain_num SMALLINT NOT NULL,
    tx_idx SMALLINT NOT NULL,
    msg_idx SMALLINT NOT NULL,
    PRIMARY KEY (
      chain_num,
      block_height,
      tx_idx,
      msg_idx
    ),
    FOREIGN KEY (
      chain_num,
      block_height,
      tx_idx,
      msg_idx,
      TYPE
    ) REFERENCES msg_event
  );
