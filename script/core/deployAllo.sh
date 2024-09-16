#!/bin/bash

# Function to dynamically map chains to variables
# Relevant issue that would deprecate this script if solved: https://github.com/foundry-rs/foundry/issues/7726
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
    "fuji")
      RPC_URL="$FUJI_RPC_URL"
      API_KEY="$FUJI_API_KEY"
      ;;
    "celo-testnet")
      RPC_URL="$CELO_TESTNET_RPC_URL"
      API_KEY="$CELO_API_KEY"
      ;;
    "celo-mainnet")
      RPC_URL="$CELO_RPC_URL"
      API_KEY="$CELO_API_KEY"
      ;;
    "arbitrum-mainnet")
      RPC_URL="$ARBITRUM_RPC_URL"
      API_KEY="$ARBITRUMSCAN_API_KEY"
      ;;
    "optimism-sepolia")
      RPC_URL="$OPTIMISM_SEPOLIA_RPC_URL"
      API_KEY="$OPTIMISTIC_ETHERSCAN_API_KEY"
      ;;
    "optimism-mainnet")
      RPC_URL="$OPTIMISM_RPC_URL"
      API_KEY="$OPTIMISTIC_ETHERSCAN_API_KEY"
      ;;
    "arbitrum-sepolia")
      RPC_URL="$ARBITRUM_SEPOLIA_RPC_URL"
      API_KEY="$ARBITRUMSCAN_API_KEY"
      ;;
    "base")
      RPC_URL="$BASE_RPC_URL"
      API_KEY="$BASESCAN_API_KEY"
      ;;
    "polygon")
      RPC_URL="$POLYGON_RPC_URL"
      API_KEY="$POLYGONSCAN_API_KEY"
      ;;
    "avalanche")
      RPC_URL="$AVALANCHE_RPC_URL"
      API_KEY="$AVASCAN_API_KEY"
      ;;
    "scroll")
      RPC_URL="$SCROLL_RPC_URL"
      API_KEY="$SCROLL_API_KEY"
      ;;
    "ftmTestnet")
      RPC_URL="$FTM_TESTNET_RPC_URL"
      API_KEY="$FTMSCAN_API_KEY"
      ;;
    "fantom")
      RPC_URL="$FTM_RPC_URL"
      API_KEY="$FTMSCAN_API_KEY"
      ;;
    "filecoin-mainnet")
      RPC_URL="$FILECOIN_RPC_URL"
      API_KEY="$FILECOIN_API_KEY"
      ;;
    "filecoin-calibration")
      RPC_URL="$FILECOIN_CALIBRATION_RPC_URL"
      API_KEY="$FILECOIN_API_KEY"
      ;;
    "sei-devnet")
      RPC_URL="$SEI_DEVNET_RPC_URL"
      API_KEY="$SEI_API_KEY"
      ;;
    "sei-mainnet")
      RPC_URL="$SEI_RPC_URL"
      API_KEY="$SEI_API_KEY"
      ;;
    "lukso-testnet")
      RPC_URL="$LUKSO_TESTNET_RPC_URL"
      API_KEY="$LUKSO_API_KEY"
      ;;
    "lukso-mainnet")
      RPC_URL="$LUKSO_RPC_URL"
      API_KEY="$LUKSO_API_KEY"
      ;;
    "zkSyncTestnet")
      RPC_URL="$ZK_SYNC_TESTNET_RPC_URL"
      API_KEY="$ZKSYNC_API_KEY"
      ;;
    "zkSyncMainnet")
      RPC_URL="$ZK_SYNC_RPC_URL"
      API_KEY="$ZKSYNC_API_KEY"
      ;;
    "local")
      RPC_URL="127.0.0.1:8545"
      API_KEY=" "
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
