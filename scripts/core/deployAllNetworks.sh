#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")

# Log file
logfile="./reports/deployment-logs/core/deploy.log"
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

networks=(
  "mumbai"
#   "goerli"
  "sepolia"
#   "arbitrum-goerli"
#   "optimism-goerli"
#   "base-testnet"
#   "celo-testnet"
#   "arbitrum-sepolia"
#   "optimism-sepolia"
#   "optimism-mainnet"
#   "celo-mainnet"
#   "arbitrum-mainnet"
#   "base"
#   "polygon"
#   "mainnet"
#   "pgn-sepolia"
#   "pgn-mainnet"
#    "arbitrum-sepolia"
#    "optimism-sepolia"
)

scripts=(
    # "core/deployRegistry"
    # "core/deployContractFactory"
    # "core/deployAllo"
    # "core/transferProxyAdminOwnership"
    "strategies/deployDonationVotingMerkleDistributionDirect"
    # "strategies/deployDonationVotingMerkleDistributionVault"
    # "strategies/deployQVSimple"
    # "strategies/deployRFPCommittee"
    # "strategies/deployRFPSimple"
    "strategies/deployDirectGrants"
    # "strategies/deployImpactStream"
)

for script in "${scripts[@]}"; do
    # Execute the commands
    for n in "${networks[@]}"; do
        mkdir -p ./reports/deployment-logs/$script/$n/$timestamp/
        cmd="bun hardhat run scripts/$script.ts --no-compile --network $n | tee ./reports/deployment-logs/$script/$n/$timestamp/deploy-$n_$timestamp.log"
        log "Executing: $cmd"
        # Extract the individual log file path from the command string
        individual_logfile=$(echo $cmd | grep -o "./reports/deployment-logs/$script/$n/[^ ]*/deploy-[^ ]*.log")
        # Remove the tee command from the command string
        cmd=${cmd%|*}
        # Define a temporary file to hold the command output
        temp_file=$(mktemp)
        {
            # Evaluate the command, redirect stderr to stdout, and tee to the temporary file
            eval $cmd 2>&1 | tee $temp_file
        }
        # Check for the specific error message in the temporary file
        grep -q "insufficient funds for gas * price + value" $temp_file && handle_insufficient_funds_error "$cmd"
        # Move the temporary file to the desired log file location
        mv $temp_file $individual_logfile
    done

    log "Deployment finished with $error_count error(s)"
done