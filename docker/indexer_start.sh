# Run migrations
for file in migrations/*; do
    psql "$DATABASE_URL" -f "${file}"
done

# Workaround
psql "$DATABASE_URL" -c "INSERT INTO chain (num, chain_id) VALUES (0, 'regen-local');"
psql "$DATABASE_URL" -c "INSERT INTO block (chain_num, height, data, time) VALUES (0, 0, '{}', NOW());"

# Start indexer
python index.py
