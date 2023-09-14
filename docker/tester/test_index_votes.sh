#!/bin/bash

# set group proposal json
cat > proposal.json <<EOL
{
  "group_policy_address": "$TEST_POLICY_ADDRESS_1",
  "messages": [],
  "metadata": "",
  "proposers": ["$TEST_USER_ADDRESS_1"]
}
EOL

# create group proposal
regen tx group submit-proposal proposal.json --from $TEST_USER_ADDRESS_1 $REGEN_TX_FLAGS

# wait for transaction to be processed
sleep 10

# set proposal id
proposal_id=$(regen q group proposals-by-group-policy $TEST_POLICY_ADDRESS_1 --output json | jq -r '.proposals[-1].id')

# vote "yes" on proposal with user 1
regen tx group vote $proposal_id $TEST_USER_ADDRESS_1 VOTE_OPTION_YES "" --from $TEST_USER_ADDRESS_1 $REGEN_TX_FLAGS

# vote "yes" on proposal with user 2
regen tx group vote $proposal_id $TEST_USER_ADDRESS_2 VOTE_OPTION_YES "" --from $TEST_USER_ADDRESS_2 $REGEN_TX_FLAGS

# wait for transactions to be processed and voting period to end
sleep 20

# check user 1 vote was indexed
if ! psql $DATABASE_URL -c "SELECT * FROM votes WHERE proposal_id=$proposal_id AND voter='$TEST_USER_ADDRESS_1';"; then
  echo "indexed vote for $TEST_USER_ADDRESS_1 not found"
  exit 1
fi

# check user 2 vote was indexed
if ! psql $DATABASE_URL -c "SELECT * FROM votes WHERE proposal_id=$proposal_id AND voter='$TEST_USER_ADDRESS_2';"; then
  echo "indexed vote for $TEST_USER_ADDRESS_2 not found"
  exit 1
fi
