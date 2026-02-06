--! Previous: sha1:a1f8ae0941fd8511e513577d60572126b2525f57
--! Hash: sha1:32b5eaee469055ba19f27aea40b058b02a8e2962

-- Add transfers table (one row per MsgSend credit line)
-- Transfers intentionally do NOT include jurisdiction/reason fields:
--   jurisdiction and reason are properties of retirements (EventRetire)
--   and are stored in the retirements table; transfers store only the transfer facts.

CREATE TABLE IF NOT EXISTS public.transfers
(
    type                    text     NOT NULL,
    tradable_amount         text     NOT NULL,
    retired_amount          text     NOT NULL,
    batch_denom             text     NOT NULL,
    sender                  text     NOT NULL,
    recipient               text     NOT NULL,
    "timestamp"             timestamp with time zone,
    block_height            bigint   NOT NULL,
    chain_num               smallint NOT NULL,
    tx_idx                  smallint NOT NULL,
    msg_idx                 smallint NOT NULL,
    tx_hash                 text     NOT NULL,
    UNIQUE (
            chain_num,
            block_height,
            tx_idx,
            msg_idx,
            batch_denom,
            sender,
            recipient
        )
);

CREATE INDEX IF NOT EXISTS transfers_sender_idx ON public.transfers USING btree (sender);
CREATE INDEX IF NOT EXISTS transfers_recipient_idx ON public.transfers USING btree (recipient);
CREATE INDEX IF NOT EXISTS transfers_batch_denom_idx ON public.transfers USING btree (batch_denom);
CREATE INDEX IF NOT EXISTS transfers_tx_hash_idx ON public.transfers USING btree (tx_hash);
