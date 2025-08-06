--! Previous: sha1:fc876ad23b772a75c10056c5b7165585c454983d
--! Hash: sha1:073b3c08122620cac334720a2c5adfd485511f88

ALTER TABLE retirements
DROP CONSTRAINT IF EXISTS retirements_tx_hash_key;

CREATE INDEX IF NOT EXISTS retirements_tx_hash_idx ON retirements (tx_hash);
