FROM golang:1.19

ENV GIT_CHECKOUT='v5.1.0'
ENV REGEN_CHAIN_ID='regen-local'

RUN apt-get update

# Clone regen ledger
RUN git clone https://github.com/regen-network/regen-ledger/ /home/regen-ledger
WORKDIR /home/regen-ledger
RUN git checkout $GIT_CHECKOUT

# Build regen binary
RUN make install

# Setup moniker, chain, homedir
RUN regen --chain-id $REGEN_CHAIN_ID init validator

# Set configuration
RUN regen config chain-id $REGEN_CHAIN_ID
RUN regen config keyring-backend test

# Update stake to uregen
RUN sed -i "s/stake/uregen/g" /root/.regen/config/genesis.json

# Add accounts
RUN printf "trouble alarm laptop turn call stem lend brown play planet grocery survey smooth seed describe hood praise whale smile repeat dry sauce front future\n\n" | regen keys --keyring-backend test add validator -i
RUN printf "firm royal equal cousin just kind token control enroll liar night kitchen actor reward ramp apology family clump install margin mail shiver explain clump\n\n" | regen keys --keyring-backend test add regen1 -i

# Set up validator
RUN regen add-genesis-account validator 1000000000uregen --keyring-backend test
RUN regen gentx validator 1000000uregen

# Set up test acount
RUN regen add-genesis-account regen1 1000000000uregen --keyring-backend test
RUN regen collect-gentxs

# Set minimum gas price
RUN sed -i "s/minimum-gas-prices = \"\"/minimum-gas-prices = \"0uregen\"/g" /root/.regen/config/app.toml