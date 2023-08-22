CREATE TABLE IF NOT EXISTS
  class_issuers (
    TYPE TEXT NOT NULL,
    block_height BIGINT NOT NULL,
    tx_idx SMALLINT NOT NULL,
    msg_idx SMALLINT NOT NULL,
    chain_num SMALLINT NOT NULL,
    TIMESTAMP timestamptz,
    tx_hash TEXT NOT NULL,
    class_id TEXT NOT NULL,
    issuer TEXT NOT NULL,
    latest BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (
      chain_num,
      block_height,
      tx_idx,
      msg_idx,
      class_id,
      issuer
    ),
    FOREIGN KEY (
      chain_num,
      block_height,
      tx_idx,
      msg_idx,
      TYPE
    ) REFERENCES msg_event
  );
