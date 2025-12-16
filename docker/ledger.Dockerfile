FROM golang:1.23.8

# Install dependencies
RUN apt-get update && apt-get install -y jq

# Set ledger version
ENV GIT_CHECKOUT='v7.0.0-rc2'

# Clone regen ledger
RUN git clone https://github.com/regen-network/regen-ledger/ /home/ledger

# Set working directory
WORKDIR /home/ledger

# Use provided version
RUN git checkout $GIT_CHECKOUT

# Build regen binary
RUN make install

# Setup moniker, chain, homedir
RUN regen --chain-id regen-local init validator

# Set configuration
RUN regen config chain-id regen-local
RUN regen config keyring-backend test

# Update stake to uregen
RUN sed -i "s/stake/uregen/g" /root/.regen/config/genesis.json

# Add accounts
RUN printf "trouble alarm laptop turn call stem lend brown play planet grocery survey smooth seed describe hood praise whale smile repeat dry sauce front future\n\n" | regen keys --keyring-backend test add validator -i
RUN printf "cool trust waste core unusual report duck amazing fault juice wish century across ghost cigar diary correct draw glimpse face crush rapid quit equip\n\n" | regen keys --keyring-backend test add user1 -i
RUN printf "music debris chicken erode flag law demise over fall always put bounce ring school dumb ivory spin saddle ostrich better seminar heart beach kingdom\n\n" | regen keys --keyring-backend test add user2 -i

# Set up validator
RUN regen genesis add-genesis-account validator 1000000000uregen --keyring-backend test

# IMPORTANT FIX: ensure 08-wasm module genesis exists (prevents EOF during gentx validation)
RUN jq '.app_state["08-wasm"] //= {}' /root/.regen/config/genesis.json > /tmp/genesis.json \
  && mv /tmp/genesis.json /root/.regen/config/genesis.json

RUN regen genesis gentx validator 1000000uregen --chain-id regen-local --keyring-backend test

# Set up user accounts
RUN regen genesis add-genesis-account user1 1000000000uregen --keyring-backend test
RUN regen genesis add-genesis-account user2 1000000000uregen --keyring-backend test

# Prepare genesis file
RUN regen genesis collect-gentxs

# Set minimum gas price
RUN sed -i "s/minimum-gas-prices = \"\"/minimum-gas-prices = \"0uregen\"/" /root/.regen/config/app.toml

# Set cors allow all origins
RUN sed -i "s/cors_allowed_origins = \[\]/cors_allowed_origins = [\"*\"]/" /root/.regen/config/config.toml

# Copy genesis state files
COPY docker/data /home/ledger/data

# Add group state to genesis
RUN jq '.app_state.group |= . + input' /root/.regen/config/genesis.json /home/ledger/data/ledger_group.json > genesis-tmp.json

# Overwrite genesis file with updated genesis file
RUN mv -f genesis-tmp.json /root/.regen/config/genesis.json

# Copy regen start script
COPY docker/scripts/ledger_start.sh /home/ledger/scripts/

# Make start script executable
RUN chmod +x /home/ledger/scripts/ledger_start.sh