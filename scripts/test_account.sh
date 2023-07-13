#!/usr/bin/env bash

set -eo pipefail

# default home directory
home=./local

# default chain id
chain_id=regen-local

# configuration
regen config chain-id "$chain_id"
regen config keyring-backend test

# add same key used in regen.Dockerfile
printf "cool trust waste core unusual report duck amazing fault juice wish century across ghost cigar diary correct draw glimpse face crush rapid quit equip\n\n" | regen keys --home "$home" --keyring-backend test add test -i
