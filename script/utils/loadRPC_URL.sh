#!/bin/bash

# Ensure the chain argument is provided
if [ -z "$1" ]; then
  echo "<chain> not provided. Usage: script/utils/loadRPC_URL.sh <chain>"
  exit 1
fi

# Source the environment variables from the .env file
source .env

# Dynamically map chains to variables
case "$1" in
	"sepolia")
		RPC_URL="$SEPOLIA_RPC_URL"
		;;
	"mainnet")
		RPC_URL="$MAINNET_RPC_URL"
		;;
	"fuji")
		RPC_URL="$FUJI_RPC_URL"
		;;
	"celo-testnet")
		RPC_URL="$CELO_TESTNET_RPC_URL"
		;;
	"celo-mainnet")
		RPC_URL="$CELO_RPC_URL"
		;;
	"arbitrum-mainnet")
		RPC_URL="$ARBITRUM_RPC_URL"
		;;
	"optimism-sepolia")
		RPC_URL="$OPTIMISM_SEPOLIA_RPC_URL"
		;;
	"optimism-mainnet")
		RPC_URL="$OPTIMISM_RPC_URL"
		;;
	"arbitrum-sepolia")
		RPC_URL="$ARBITRUM_SEPOLIA_RPC_URL"
		;;
	"base")
		RPC_URL="$BASE_RPC_URL"
		;;
	"polygon")
		RPC_URL="$POLYGON_RPC_URL"
		;;
	"avalanche")
		RPC_URL="$AVALANCHE_RPC_URL"
		;;
	"scroll")
		RPC_URL="$SCROLL_RPC_URL"
		;;
	"ftmTestnet")
		RPC_URL="$FTM_TESTNET_RPC_URL"
		;;
	"fantom")
		RPC_URL="$FTM_RPC_URL"
		;;
	"filecoin-mainnet")
		RPC_URL="$FILECOIN_RPC_URL"
		;;
	"filecoin-calibration")
		RPC_URL="$FILECOIN_CALIBRATION_RPC_URL"
		;;
	"sei-devnet")
		RPC_URL="$SEI_DEVNET_RPC_URL"
		;;
	"sei-mainnet")
		RPC_URL="$SEI_RPC_URL"
		;;
	"lukso-testnet")
		RPC_URL="$LUKSO_TESTNET_RPC_URL"
		;;
	"lukso-mainnet")
		RPC_URL="$LUKSO_RPC_URL"
		;;
	"zkSyncTestnet")
		RPC_URL="$ZK_SYNC_TESTNET_RPC_URL"
		;;
	"zkSyncMainnet")
		RPC_URL="$ZK_SYNC_RPC_URL"
		;;
	"local")
		RPC_URL="127.0.0.1:8545"
		;;
	*)
		echo "Error: Unknown chain '$1'"
		exit 1
		;;
esac

# Check if RPC _URL is set
if [ -z "$RPC_URL" ]; then
	echo "Error: RPC_URL missing."
	exit 1
fi

echo "$RPC_URL"
