#!/usr/bin/env bash

set -eo pipefail

# default home directory
home=./local

# default tmp directory
tmp=./tmp

# default chain id
chain_id=regen-local

# configuration
regen config chain-id "$chain_id"
regen config keyring-backend test

# make tmp directory
mkdir -p $tmp

# test account address
address=regen1l2pwmzk96ftmmt5egpjulyqtneygmmzndf7csk

# transaction flags
tx_flags="--from $address --home $home --keyring-backend test --chain-id $chain_id --yes"

# group members json
cat > "$tmp"/members.json <<EOL
{
  "members": [
    {
      "address": "$address",
      "weight": "1",
      "metadata": ""
    }
  ]
}
EOL

regen tx group create-group "$address" "" "$tmp"/members.json $tx_flags

sleep 10 # wait for transaction to be processed

# group policy json
cat > "$tmp"/policy.json <<EOL
{
  "@type": "/cosmos.group.v1.ThresholdDecisionPolicy",
  "threshold": "1",
  "windows": {
    "voting_period": "20s",
    "min_execution_period": "0s"
  }
}
EOL

regen tx group create-group-policy "$address" 1 "" "$tmp"/policy.json $tx_flags

sleep 10 # wait for transaction to be processed

policy_address=$(regen q group group-policies-by-group 1 --output json | jq -r '.group_policies[-1].address')

# group proposal json
cat > "$tmp"/proposal.json <<EOL
{
  "group_policy_address": "$policy_address",
  "messages": [],
  "metadata": "",
  "proposers": ["$address"]
}
EOL

regen tx group submit-proposal "$tmp"/proposal.json $tx_flags

sleep 10 # wait for transaction to be processed

proposal_id=$(regen q group proposals-by-group-policy "$policy_address" --output json | jq -r '.proposals[-1].id')

regen tx group vote "$proposal_id" "$address" VOTE_OPTION_YES "" $tx_flags

sleep 20 # wait for transaction to be process and voting period to end

regen tx group exec "$proposal_id" $tx_flags
