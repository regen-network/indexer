--! Previous: sha1:23379758e3a742625d5262c472693435196be95f
--! Hash: sha1:8aa6f840171d1c0076e70fbee8dd9b56f794a03d

ALTER TABLE retirements
DROP CONSTRAINT IF EXISTS retirements_tx_hash_key;

ALTER TABLE retirements
ADD CONSTRAINT retirements_tx_hash_key UNIQUE (tx_hash);
