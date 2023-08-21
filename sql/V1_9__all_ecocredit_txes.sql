DROP INDEX IF EXISTS tx_data_tx_response_code_idx;

CREATE INDEX IF NOT EXISTS tx_data_tx_response_code_idx ON tx USING BTREE ((DATA -> 'tx_response' -> 'code'));

CREATE INDEX IF NOT EXISTS msg_event_type_idx ON msg_event (
  TYPE
);

DROP FUNCTION IF EXISTS all_ecocredit_txes;

CREATE FUNCTION all_ecocredit_txes () RETURNS SETOF tx AS $$
    select tx.*
    from tx
    natural join msg_event as me
    where
      data ->'tx_response'->'code' = '0'
      and me.type like 'regen.ecocredit.%'
    order by tx.block_height desc
$$ LANGUAGE SQL STABLE;
