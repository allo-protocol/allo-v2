#!/bin/bash

# Function to dynamically map chains to variables
# Relevant issue that would deprecate this script if solved: https://github.com/foundry-rs/foundry/issues/7726
# TODO: add networks
deploy() {
  chain=$1
  case "$chain" in
    "sepolia")
      RPC_URL="$SEPOLIA_RPC_URL"
      API_KEY="$ETHERSCAN_API_KEY"
      ;;
    "mainnet")
      RPC_URL="$MAINNET_RPC_URL"
      API_KEY="$ETHERSCAN_API_KEY"
      ;;
    *)
      echo "Error: Unknown chain '$chain'"
      exit 1
      ;;
  esac

  # Check if required variables are set
  if [ -z "$RPC_URL" ] || [ -z "$API_KEY" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: Missing environment variables."
    exit 1
  fi

  # Deploy script with resolved variables
  forge script DeployAllo --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY" --verify --etherscan-api-key "$API_KEY"
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
