#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")

# Log file
logfile="./reports/deployment-logs/strategies/deploy.log"
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

mkdir -p ./reports/deployment-logs/strategies/$timestamp

# Deployment commands
commands=(
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network goerli | tee ./reports/deployment-logs/strategies/$timestamp/deploy-goerli.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network sepolia | tee ./reports/deployment-logs/strategies/$timestamp/deploy-sepolia_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network arbitrum-goerli | tee ./reports/deployment-logs/strategies/$timestamp/deploy-arbitrum-goerli_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network optimism-goerli | tee ./reports/deployment-logs/strategies/$timestamp/deploy-optimism-goerli_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network base-testnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-base-testnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network celo-testnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-celo-testnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network mumbai | tee ./reports/deployment-logs/strategies/$timestamp/deploy-mumbai_$timestamp.log"
    # "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network pgn-sepolia | tee ./reports/deployment-logs/strategies/$timestamp/deploy-pgn-sepolia_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network mainnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-mainnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network optimism-mainnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-optimism-mainnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network celo-mainnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-celo-mainnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network arbitrum-mainnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-arbitrum-mainnet_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network base | tee ./reports/deployment-logs/strategies/$timestamp/deploy-base_$timestamp.log"
    "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network polygon | tee ./reports/deployment-logs/strategies/$timestamp/deploy-polygon_$timestamp.log"
    # "bun hardhat run scripts/strategies/_deployAllStrategies.ts --network pgn-mainnet | tee ./reports/deployment-logs/strategies/$timestamp/deploy-pgn-mainnet_$timestamp.log"
)

# Execute the commands
for cmd in "${commands[@]}"; do
    log "Executing: $cmd"
    # Extract the individual log file path from the command string
    individual_logfile=$(echo $cmd | grep -o './reports/deployment-logs/strategies/[^ ]*/deploy-[^ ]*.log')
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
