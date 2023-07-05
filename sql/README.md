## Running these migrations

You must set the `DATABASE_URL` environment variable and then run the following command, e.g.:

```
$ cd sql
$ DATABASE_URL=postgres://postgres:postgres@localhost:5432/indexer ./run_all_migrations.sh
```

## Adding migrations

Each time you add a new migration to the `sql` folder, add it to the end of the `run_all_migrations.sh` script.
