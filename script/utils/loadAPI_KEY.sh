#!/bin/bash

# Ensure the chain argument is provided
if [ -z "$1" ]; then
  echo "<chain> not provided. Usage: script/utils/loadAPI_KEY.sh <chain>"
  exit 1
fi

# Source the environment variables from the .env file
source .env

# Dynamically map chains to variables
case "$1" in
	"sepolia")
		API_KEY="$ETHERSCAN_API_KEY"
		;;
	"mainnet")
		API_KEY="$ETHERSCAN_API_KEY"
		;;
	"fuji")
		API_KEY="$FUJI_API_KEY"
		;;
	"celo-testnet")
		API_KEY="$CELO_API_KEY"
		;;
	"celo-mainnet")
		API_KEY="$CELO_API_KEY"
		;;
	"arbitrum-mainnet")
		API_KEY="$ARBITRUMSCAN_API_KEY"
		;;
	"optimism-sepolia")
		API_KEY="$OPTIMISTIC_ETHERSCAN_API_KEY"
		;;
	"optimism-mainnet")
		API_KEY="$OPTIMISTIC_ETHERSCAN_API_KEY"
		;;
	"arbitrum-sepolia")
		API_KEY="$ARBITRUMSCAN_API_KEY"
		;;
	"base")
		API_KEY="$BASESCAN_API_KEY"
		;;
	"polygon")
		API_KEY="$POLYGONSCAN_API_KEY"
		;;
	"avalanche")
		API_KEY="$AVASCAN_API_KEY"
		;;
	"scroll")
		API_KEY="$SCROLL_API_KEY"
		;;
	"ftmTestnet")
		API_KEY="$FTMSCAN_API_KEY"
		;;
	"fantom")
		API_KEY="$FTMSCAN_API_KEY"
		;;
	"filecoin-mainnet")
		API_KEY="$FILECOIN_API_KEY"
		;;
	"filecoin-calibration")
		API_KEY="$FILECOIN_API_KEY"
		;;
	"sei-devnet")
		API_KEY="$SEI_API_KEY"
		;;
	"sei-mainnet")
		API_KEY="$SEI_API_KEY"
		;;
	"lukso-testnet")
		API_KEY="$LUKSO_API_KEY"
		;;
	"lukso-mainnet")
		API_KEY="$LUKSO_API_KEY"
		;;
	"zkSyncTestnet")
		API_KEY="$ZKSYNC_API_KEY"
		;;
	"zkSyncMainnet")
		API_KEY="$ZKSYNC_API_KEY"
		;;
	"local")
		API_KEY=" "
		;;
	*)
		echo "Error: Unknown chain '$1'"
		exit 1
		;;
esac

# Check if RPC _URL is set
if [ -z "$API_KEY" ]; then
	echo "Error: API_KEY missing."
	exit 1
fi

echo "$API_KEY"
