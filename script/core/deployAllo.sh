#!/bin/bash

# Relevant issue that would deprecate this script if solved: https://github.com/foundry-rs/foundry/issues/7726
deploy() {
  chain=$1
  
  RPC_URL=$(script/utils/loadRPC_URL.sh $chain)
  API_KEY=$(script/utils/loadAPI_KEY.sh $chain)

  # Check if required variables are set
  if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: Missing DEPLOYER_PRIVATE_KEY."
    exit 1
  fi

  # Deploy script with resolved variables
  if [ "$chain" == "zkSyncMainnet" ] || [ "$chain" == "zkSyncTestnet" ]; then
    forge script DeployAllo --zksync --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY" --verify --etherscan-api-key "$API_KEY"
  elif [ "$chain" == "local" ]; then
    # Use anvil's default account's private key
    forge script DeployAllo --rpc-url "$RPC_URL" --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  else
    forge script DeployAllo --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY" --verify --etherscan-api-key "$API_KEY"
  fi
}

# Ensure the chain argument is provided
if [ -z "$1" ]; then
  echo "<chain> not provided. Usage: script/deployAllo.sh <chain>"
  exit 1
fi

# Source the environment variables from the .env file
source .env

# Call the deploy function with the provided chain argument
deploy "$1"
