# Run migrations
for file in migrations/*; do
    psql "$DATABASE_URL" -f "${file}"
done

# Start indexer
python index.py
