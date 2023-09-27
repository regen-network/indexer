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

# vote "yes" on proposal with user
regen tx group vote "$proposal_id" $TEST_USER_ADDRESS_1 VOTE_OPTION_YES "" --from $TEST_USER_ADDRESS_1 $REGEN_TX_FLAGS

# wait for transactions to be processed and voting period to end
sleep 20

# execute proposal
regen tx group exec "$proposal_id" --from $TEST_USER_ADDRESS_1 $REGEN_TX_FLAGS

# wait for transaction to be processed
sleep 10

# check proposal was indexed
if ! psql "$DATABASE_URL" -c "SELECT * FROM proposals WHERE proposal_id=$proposal_id;"; then
  echo "indexed proposal not found"
  exit 1
fi

# TODO(#42): executor result should be success after successful execution

# check proposal executor result
#if ! psql "$DATABASE_URL" -c "SELECT * FROM proposals WHERE proposal_id=$proposal_id AND executor_result=PROPOSAL_EXECUTOR_RESULT_SUCCESS;"; then
#  echo "indexed proposal with PROPOSAL_EXECUTOR_RESULT_SUCCESS not found"
#  exit 1
#fi
