CREATE TABLE IF NOT EXISTS
  proposals (
    TYPE TEXT NOT NULL,
    proposal_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    tally_result JSONB NOT NULL,
    metadata JSONB NOT NULL,
    TIMESTAMP timestamptz,
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
