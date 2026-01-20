--! Previous: sha1:073b3c08122620cac334720a2c5adfd485511f88
--! Hash: sha1:74516a9f99b063fa9f29446b72cf800efa963150

BEGIN;

-- 1. Create a Partial Index for IRI lookups
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_msg_event_attr_iri_data_v_partial') THEN
        CREATE INDEX idx_msg_event_attr_iri_data_v_partial 
        ON public.msg_event_attr (value) 
        WHERE (type LIKE 'regen.data.v%.Event%');
    END IF;
END $$;

-- 2. Create the Unified View
-- We use LEFT JOIN so that Anchors (which lack attestors) still appear.
CREATE OR REPLACE VIEW public.unified_data_events AS
SELECT 
    iri_row.chain_num,
    iri_row.block_height,
    iri_row.tx_idx,
    iri_row.msg_idx,
    iri_row.type AS event_type,
    -- Strip double quotes from the beginning and end of the string
    trim(both '"' from iri_row.value) AS iri,
    trim(both '"' from attestor_row.value) AS attestor,
    -- Encode the bytea hash to a hex string for easier use in GraphQL
    '0x' || encode(t.hash, 'hex') AS tx_hash,
    TRIM(BOTH '"' FROM (t.data -> 'tx_response' -> 'timestamp')::text) AS timestamp
FROM public.msg_event_attr iri_row
-- Join with tx table using the composite key
INNER JOIN public.tx t ON (
    iri_row.chain_num = t.chain_num AND 
    iri_row.block_height = t.block_height AND 
    iri_row.tx_idx = t.tx_idx
)
-- Left join for attestor (optional, as Anchors don't have one)
LEFT JOIN public.msg_event_attr attestor_row ON (
    iri_row.chain_num = attestor_row.chain_num AND 
    iri_row.block_height = attestor_row.block_height AND 
    iri_row.tx_idx = attestor_row.tx_idx AND 
    iri_row.msg_idx = attestor_row.msg_idx AND
    attestor_row.key = 'attestor'
)
WHERE iri_row.key = 'iri'
  AND (iri_row.type LIKE 'regen.data.v%.EventAnchor' 
       OR iri_row.type LIKE 'regen.data.v%.EventAttest');

-- 3. PostGraphile Smart Comments
-- This tells PostGraphile to treat the combination of these 4 columns as a Primary Key.
COMMENT ON VIEW public.unified_data_events IS 
  E'@primaryKey chain_num,block_height,tx_idx,msg_idx\n@name unifiedDataEvent';

-- 4. Permissions
GRANT SELECT ON public.unified_data_events TO public;

COMMIT;
