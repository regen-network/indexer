--! Previous: sha1:a1f8ae0941fd8511e513577d60572126b2525f57
--! Hash: sha1:a024a5a79fcbb3709b9298d664b2c48c8483bc8f

-- Add transfers view (replaces table approach)
-- Solves multi-batch correlation issue by extracting data directly
-- from the msg.data JSON which preserves the proper credits array structure
-- One row per unique batch_denom per MsgSend (aggregates duplicate batch_denoms)

CREATE OR REPLACE VIEW public.transfers AS
SELECT
  'regen.ecocredit.v1.EventTransfer'::text AS type,
  SUM(
    CASE
      WHEN credit->>'tradable_amount' = '' THEN 0
      ELSE (credit->>'tradable_amount')::numeric
    END
  )::text AS tradable_amount,
  SUM(
    CASE
      WHEN credit->>'retired_amount' = '' THEN 0
      ELSE (credit->>'retired_amount')::numeric
    END
  )::text AS retired_amount,
  credit->>'batch_denom' AS batch_denom,
  msg.data->>'sender' AS sender,
  msg.data->>'recipient' AS recipient,
  (TRIM(BOTH '"' FROM (tx.data->'tx_response'->'timestamp')::text))::timestamp with time zone AS "timestamp",
  msg.block_height,
  msg.chain_num,
  msg.tx_idx,
  msg.msg_idx,
  encode(tx.hash, 'hex') AS tx_hash
FROM msg
CROSS JOIN LATERAL jsonb_array_elements(msg.data->'credits') AS credit
JOIN tx ON
  msg.block_height = tx.block_height
  AND msg.tx_idx = tx.tx_idx
  AND msg.chain_num = tx.chain_num
WHERE msg.data->>'@type' = '/regen.ecocredit.v1.MsgSend'
GROUP BY
  credit->>'batch_denom',
  msg.data->>'sender',
  msg.data->>'recipient',
  tx.data->'tx_response'->'timestamp',
  msg.block_height,
  msg.chain_num,
  msg.tx_idx,
  msg.msg_idx,
  tx.hash;

-- Add indexes on underlying tables for view performance
CREATE INDEX IF NOT EXISTS msg_data_type_idx ON public.msg USING btree (((data->>'@type')));
CREATE INDEX IF NOT EXISTS msg_data_sender_idx ON public.msg USING gin ((data->'sender'));
CREATE INDEX IF NOT EXISTS msg_data_recipient_idx ON public.msg USING gin ((data->'recipient'));
