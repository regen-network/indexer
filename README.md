# indexer

Blockchain indexer and database

## E2E Testing

This project uses docker for e2e testing.

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
