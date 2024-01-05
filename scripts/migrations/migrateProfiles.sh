#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")

# Log file
logfile="./reports/migrations/profiles.log"
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

mkdir -p ./reports/migrations/profile/$timestamp

networks=(
  "goerli"
#   "polygon"
#   "mainnet"
#   "optimism-mainnet"
#   "celo-mainnet"
#   "arbitrum-mainnet"
#   "base"
#   "pgn-mainnet"
)

for n in  "${networks[@]}"; do
  command="bun hardhat run scripts/migrations/migrateProfiles.ts --no-compile --network $n | tee ./reports/migrations/profile-$n_$timestamp.log"
  log "Executing: $command"
  # Extract the individual log file path from the command string
  individual_logfile=$(echo $command | grep -o './reports/migrations/profile-[^ ]*.log')
  # Remove the tee command from the command string
  command=${command%|*}
  # Define a temporary file to hold the command output
  temp_file=$(mktemp)
  {
      # Evaluate the command, redirect stderr to stdout, and tee to the temporary file
      eval $command 2>&1 | tee $temp_file
  }
done