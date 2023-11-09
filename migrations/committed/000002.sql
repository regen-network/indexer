--! Previous: sha1:5ad90bce5c5fb68d0a8f886b6c07fb280ccd2c42
--! Hash: sha1:80425329666e5d20b5fbb7b6179f3d19acceeb76

-- support for similarity of text using trigram matching
CREATE extension IF NOT EXISTS pg_trgm;

-- drop the previous index that wasn't being useful for LIKE operations
-- and add a new index using gin_trgm_ops operator class from pg_trgm extension.
DROP INDEX IF EXISTS msg_data_type_idx;
CREATE INDEX IF NOT EXISTS msg_data_type_gin_idx ON msg USING gin  ((data->>'@type') gin_trgm_ops);
