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
#   "fuji"
#   "sepolia"
#   "celo-testnet"
#   "arbitrum-sepolia"
#   "optimism-sepolia" # Error calling deploy() function for contract DirectGrantsLiteStrategy
#   "optimism-mainnet"
#   "celo-mainnet"
#   "arbitrum-mainnet"
#   "base"
#   "polygon"
#   "mainnet"
#   "avalanche"
#   "scroll"
#   "ftmTestnet"
#   "fantom"
#   "filecoin-mainnet"
#   "filecoin-calibration"
#   "sei-devnet"
#   "sei-mainnet"
#   "lukso-testnet"
#   "lukso-mainnet"
#   "metisAndromeda"
#   "gnosis"

#  === ZkSync Era ===
#   "zkSyncTestnet"
#   "zkSyncMainnet"
#  ==================
)

scripts=(
    # "core/deployRegistry"
    # "core/deployContractFactory"
    # "core/deployAllo"
   
    # "strategies/deployDonationVotingMerkleDistributionDirect"
    # "strategies/deployDirectGrantsLite"
    # "strategies/deployDirectAllocation"
    
    # "core/transferProxyAdminOwnership"
    # "strategies/deployDirectGrants"
    # "strategies/deployDonationVotingMerkleDistributionVault"
    # "strategies/deployQVSimple"
    # "strategies/deployRFPCommittee"
    # "strategies/deployRFPSimple"
    # "strategies/deployImpactStream"

    #  === ZkSync Era ===
    # "zksync/deployEraRegistry"
    # "zksync/deployEraAllo"
    # "zksync/deployEraContractFactory"
    # "zksync/strategies/deployEraDonationVotingMerkleDistributionDirect"
    # "zksync/strategies/deployEraDirectGrants"
    # "zksync/strategies/deployEraDirectGrantsLite"
    # "zksync/factory/deployDGLFactory"
    # "zksync/factory/deployDVMDTFactory"
)

for script in "${scripts[@]}"; do
    # Execute the commands
    for n in "${networks[@]}"; do
        mkdir -p ./reports/deployment-logs/$script/$n/$timestamp/

        if [ "$n" == "zkSyncTestnet" ] || [ "$n" == "zkSyncMainnet" ]; then
            cmd="bun hardhat deploy-zksync --network $n --config era.hardhat.config.ts --script $script.ts | tee ./reports/deployment-logs/$script/$n/$timestamp/deploy-$n_$timestamp.log"
        else
            cmd="bun hardhat run scripts/$script.ts --no-compile --network $n | tee ./reports/deployment-logs/$script/$n/$timestamp/deploy-$n_$timestamp.log"
        fi

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