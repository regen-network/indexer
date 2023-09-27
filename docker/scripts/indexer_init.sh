#!/bin/bash

# run migrations
(cd sql && ./run_all_migrations.sh)

# workaround for indexer starting with new chain
psql "$DATABASE_URL" -c "INSERT INTO chain (
  num,
  chain_id
) VALUES (
  1,
  'regen-local'
)"
psql "$DATABASE_URL" -c "INSERT INTO block (
  chain_num,
  height,
  data,
  time
) VALUES (
  1,
  0,
  '{}',
  now()
)"
