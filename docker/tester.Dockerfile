FROM golang:1.19

# Install dependencies
RUN apt-get update
RUN apt-get install jq libpq-dev postgresql-client -y

# Set version and chain
ENV GIT_CHECKOUT='v5.1.2'

# Set database url
ENV DATABASE_URL='postgres://postgres:password@localhost:5432/postgres'

# Set test addresses
ENV TEST_USER_ADDRESS_1=regen1l2pwmzk96ftmmt5egpjulyqtneygmmzndf7csk
ENV TEST_USER_ADDRESS_2=regen14v5z5yyl5unnyu6q3ele8ze9jev6y0m7tx6gct
ENV TEST_POLICY_ADDRESS_1=regen1afk9zr2hn2jsac63h4hm60vl9z3e5u69gndzf7c99cqge3vzwjzs475lmr

# Set transaction flags
ENV REGEN_TX_FLAGS="--keyring-backend test --chain-id regen-local --yes"

# Clone regen ledger
RUN git clone https://github.com/regen-network/regen-ledger/ /home/tester

# Set working directory
WORKDIR /home/tester

# Use provided version
RUN git checkout $GIT_CHECKOUT

# Build regen binary
RUN make install

# Set configuration
RUN regen config chain-id regen-local
RUN regen config keyring-backend test

# Add accounts
RUN printf "cool trust waste core unusual report duck amazing fault juice wish century across ghost cigar diary correct draw glimpse face crush rapid quit equip\n\n" | regen keys --keyring-backend test add user1 -i
RUN printf "music debris chicken erode flag law demise over fall always put bounce ring school dumb ivory spin saddle ostrich better seminar heart beach kingdom\n\n" | regen keys --keyring-backend test add user2 -i

# Copy tester start script
COPY docker/scripts/tester_start.sh /home/tester/scripts/

# Copy tester test scripts
COPY docker/tester/ /home/tester/scripts/

# Make start script executable
RUN ["chmod", "+x", "/home/tester/scripts/tester_start.sh"]

# Make test scripts executable
RUN ["chmod", "+x", "/home/tester/scripts/test_index_proposals.sh"]
RUN ["chmod", "+x", "/home/tester/scripts/test_index_votes.sh"]
