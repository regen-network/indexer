#!/bin/bash

INDEXER_INITIALIZED="INDEXER_INITIALIZED"

# initialize indexer if not yet initialized
if [ ! -e $INDEXER_INITIALIZED ]; then

  # set indexer initialized
  touch $INDEXER_INITIALIZED

  echo "First start, running init script..."

  # run indexer init script
  /home/indexer/docker/scripts/indexer_init.sh
fi

# wait for ledger to start
sleep 10 # TODO: improve error handling if node unavailable

# start indexer
python main.py
