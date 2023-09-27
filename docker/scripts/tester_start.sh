#!/bin/bash

set -eo pipefail

# wait for indexer to start
sleep 5

# run tester test scripts
/home/tester/scripts/test_index_proposals.sh
/home/tester/scripts/test_index_votes.sh

# exit without error
exit 0
