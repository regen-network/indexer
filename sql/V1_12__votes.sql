ALTER TABLE IF EXISTS proposals
DROP CONSTRAINT IF EXISTS proposals_proposal_id_ux;

ALTER TABLE IF EXISTS proposals
ADD CONSTRAINT proposals_proposal_id_ux UNIQUE (chain_num, proposal_id);

CREATE TABLE IF NOT EXISTS
  votes (
    TYPE TEXT NOT NULL,
    block_height BIGINT NOT NULL,
    tx_idx SMALLINT NOT NULL,
    msg_idx SMALLINT NOT NULL,
    chain_num SMALLINT NOT NULL,
    TIMESTAMP timestamptz,
    tx_hash TEXT NOT NULL,
    proposal_id BIGINT NOT NULL,
    voter TEXT NOT NULL,
    OPTION TEXT NOT NULL,
    metadata TEXT NOT NULL,
    submit_time timestamptz NOT NULL,
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
    ) REFERENCES msg_event,
    FOREIGN KEY (chain_num, proposal_id) REFERENCES proposals (chain_num, proposal_id)
  );

DROP INDEX IF EXISTS votes_proposal_id_chain_num_idx;

CREATE INDEX IF NOT EXISTS votes_proposal_id_chain_num_idx ON votes (proposal_id, chain_num);
