#!/bin/bash

# Relevant issue that could deprecate this script if solved: https://github.com/foundry-rs/foundry/issues/7726
runScript() {
  chain=$1
  scriptName=$2
  
  RPC_URL=$(script/utils/loadRPC_URL.sh $chain)

  # Check if required variables are set
  if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: Missing DEPLOYER_PRIVATE_KEY."
    exit 1
  fi

  # Deploy script with resolved variables
  if [ "$chain" == "zkSyncMainnet" ] || [ "$chain" == "zkSyncTestnet" ]; then
    forge script "$scriptName" --zksync --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY"
  else
    forge script "$scriptName" --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY"
  fi
}

# Ensure the chain argument is provided
if [ -z "$1" ]; then
  echo "<chain> not provided. Usage: script/core/interaction/runScript.sh <chain> <scriptName>"
  exit 1
fi

# Ensure the script name argument is provided
if [ -z "$2" ]; then
  echo "<scriptName> not provided. Usage: script/core/interaction/runScript.sh <chain> <scriptName>"
  exit 1
fi

# Source the environment variables from the .env file
source .env

# Call the generic run script function with the provided chain argument
runScript "$1" "$2"
