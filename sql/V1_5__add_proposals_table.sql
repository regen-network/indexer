CREATE TABLE IF NOT EXISTS
  proposals (
    TYPE TEXT NOT NULL,
    block_height BIGINT NOT NULL,
    tx_idx SMALLINT NOT NULL,
    msg_idx SMALLINT NOT NULL,
    chain_num SMALLINT NOT NULL,
    TIMESTAMP timestamptz,
    tx_hash TEXT NOT NULL,

    proposal_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    group_policy_address TEXT NOT NULL,
    metadata TEXT NOT NULL,
    proposers TEXT[] NOT NULL,
    submit_time timestamptz,
    group_version BIGINT NOT NULL,
    group_policy_version BIGINT NOT NULL,
    final_tally_result JSONB NOT NULL,
    voting_period_end timestamptz NOT NULL,
    executor_result TEXT NOT NULL,
    messages JSONB NOT NULL,

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
