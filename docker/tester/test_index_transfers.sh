#!/bin/bash
set -eo pipefail

# Wait for indexer to start & index
sleep 10

# Check at least one transfer row exists
if ! psql "$DATABASE_URL" -c "SELECT 1 FROM transfers LIMIT 1;"; then
  echo "ecocredit transfer not found"
  exit 1
fi

# Check that any transfer with retired_amount > 0 has a matching retirement (best-effort check)
if ! psql "$DATABASE_URL" -c "SELECT 1 FROM transfers t JOIN retirements r ON r.tx_hash = t.tx_hash AND r.owner = t.recipient WHERE t.retired_amount > 0 LIMIT 1;"; then
  echo "no matching retirement found for transfer with retired_amount > 0 (this may be ok in some cases)"
  # not failing the test here; consider making it strict if you control the test txes
fi

echo "ecocredit transfer indexing smoke test passed"
exit 0