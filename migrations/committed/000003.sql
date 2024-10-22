--! Previous: sha1:80425329666e5d20b5fbb7b6179f3d19acceeb76
--! Hash: sha1:23379758e3a742625d5262c472693435196be95f

ALTER TABLE public.retirements
ADD COLUMN IF NOT EXISTS batch_denoms text[] DEFAULT ARRAY[]::text[] NOT NULL;

UPDATE public.retirements
SET batch_denoms = ARRAY[batch_denom];

-- TODO later once app fully migrated
-- ALTER TABLE public.retirements
-- DROP COLUMN IF EXISTS batch_denom;
