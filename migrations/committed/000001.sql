--! Previous: -
--! Hash: sha1:5ad90bce5c5fb68d0a8f886b6c07fb280ccd2c42

CREATE INDEX IF NOT EXISTS msg_data_type_idx ON msg USING BTREE ((DATA -> '@type'));

DROP FUNCTION IF EXISTS all_ecocredit_txes;

CREATE FUNCTION public.all_ecocredit_txes() RETURNS SETOF public.tx
  LANGUAGE sql STABLE
  AS $$
    select tx.*
    from tx
    inner join msg using (chain_num, block_height, tx_idx)
    where
      tx.data ->'tx_response'->'code' = '0' and
      msg.data->>'@type' like '/regen.ecocredit.%'
    order by tx.block_height desc
$$;
