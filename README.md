# indexer

This project indexes data from the [Regen Ledger](https://github.com/regen-network/regen-ledger/) and stores it in a postgresql database.
It is built as single python script that spawns independent processes for indexing application specific data.
This database is currently being used for several purposes in relation to [the Regen Marketplace](https://github.com/regen-network/regen-web) and [the Regen Groups UI](https://github.com/regen-network/groups-ui).

## GraphQL API

The [Regen Server](https://github.com/regen-network/regen-server/) provides a GraphQL API for accessing the indexer database:

https://api.regen.network/indexer/v1/graphiql

Both the Regen Groups UI and the Regen Marketplace use this API to access the data.

## Dependencies

In order to run this project locally you will need the following:

1. a [local testnet](https://docs.regen.network/ledger/get-started/local-testnet.html) version of regen-ledger with REST API and RPC enabled
2. a postgresql database running, either locally or through [docker](#local-development-with-docker)
3. a working python3 installation
4. the [poetry package manager](https://python-poetry.org/docs/#installation) for python installed

## Configuration

All configuration values are set up via environment variables, see `.env-example`.
During local development these values will be something like:

```
DATABASE_URL=postgres://postgres:postgres@localhost:5432/indexer
REGEN_RPC=http://localhost:26657
REGEN_API=http://localhost:1317
```

The `DATABASE_URL` is used both for the application to connect as well as the migration tool.

## Architecture

The main entrypoint script is `main.py`, this script spawns all other indexing processes.
The primary indexing process is contained in `index_blocks.py`, this process indexes all block-level data by looping through transactions and messages.

The scripts that index regen-specific application data are:

- `index_class_issuers.py`
- `index_proposals.py`
- `index_retires.py`
- `index_votes.py`

## Running the main script

After successfully running a local testnet version of Regen Ledger and preparing a database you can run the scripts with:

```
$ poetry install
$ poetry run python main.py
```

## Managing the database with migrations

See [migrations/README.md](migrations/README.md).

## Heroku Deployment

This application is deployed in a pipeline in heroku.
There is a staging environment in addition to the production environment.

## Local development with docker

You can make use of docker to bring up the various components required for development.
See the `docker-compose.yml` for information on what the components are.
The following command will bring up the system:

```
docker-compose up
```

## E2E Testing

Currently we have a set of e2e tests written using the Regen CLI and shell scripts.
This project uses docker for e2e testing in CI.

### Instructions for running e2e tests with docker

Build docker containers (this only needs to be run once or after making changes):

```sh
docker-compose build
```

Run docker containers (and continue running non-tester containers after test scripts):

```sh
docker-compose up
```

Run docker containers (and stop all containers after test scripts):

```sh
docker-compose up --abort-on-container-exit --exit-code-from tester
```

Stop and remove containers (clean up previous run before running again):

```sh
docker-compose down
```
