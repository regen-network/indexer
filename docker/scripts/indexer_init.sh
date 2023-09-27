#!/bin/bash

psql "$DATABASE_URL" -c "CREATE DATABASE indexer"
psql "$DATABASE_URL" -c "CREATE DATABASE indexer_shadow"

# run migrations
npm run db-init

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
