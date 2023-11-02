#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")

# Log file
logfile="./reports/drainer/drain.log"
error_count=0

# Function to log messages
log() {
    local msg=$1
    echo "$(date +'%Y%m%d_%H%M%S') - $msg" | tee -a $logfile
}

# Function to handle errors
error_handler() {
    local error_code=$1
    local cmd=$2
    log "Error code $error_code while executing: $cmd"
    ((error_count++))
}


handle_insufficient_funds_error() {
    local cmd=$1
    log "Insufficient funds error while executing: $cmd"
}

mkdir -p ./reports/drainer/drain/$timestamp

networks=(
  "mumbai"
  "goerli"
  "sepolia"
  "arbitrum-goerli"
  "optimism-goerli"
  "base-testnet"
  "celo-testnet"
  # "pgn-sepolia"
  "polygon"
  "mainnet"
  "optimism-mainnet"
  "celo-mainnet"
  "arbitrum-mainnet"
  "base"
  # "pgn-mainnet"
)

# Deployment commands

for n in  "${networks[@]}"; do
  command="bun hardhat run scripts/other/walletDrainer.ts --no-compile --network $n | tee ./reports/drainer/drain/$timestamp/drain-$n_$timestamp.log"
  log "Executing: $command"
  # Extract the individual log file path from the command string
  individual_logfile=$(echo $command | grep -o './reports/drainer/drain/[^ ]*/drain-[^ ]*.log')
  # Remove the tee command from the command string
  command=${command%|*}
  # Define a temporary file to hold the command output
  temp_file=$(mktemp)
  {
      # Evaluate the command, redirect stderr to stdout, and tee to the temporary file
      eval $command 2>&1 | tee $temp_file
  }
done