#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")

# Log file
logfile="./reports/upgrade-logs/upgrade.log"
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

mkdir -p ./reports/upgrade-logs/$timestamp

flag=$1
commands=[]

# Execute the commands
execute_commands() {
    local commands=("$@") # accept an array argument

    for cmd in "${commands[@]}"; do
        log "Executing: $cmd"
        # Extract the individual log file path from the command string
        individual_logfile=$(echo $cmd | grep -o './reports/upgrade-logs/[^ ]*/upgrade-[^ ]*.log')
        # Remove the tee command from the command string
        cmd=${cmd%|*}
        # Define a temporary file to hold the command output
        temp_file=$(mktemp)
        {
            # Evaluate the command, redirect stderr to stdout, and tee to the temporary file
            eval $cmd 2>&1 | tee $temp_file
        }
        # Check for the specific error message in the temporary file
        grep -q "insufficient funds for gas * price + value" "$temp_file" && handle_insufficient_funds_error "$cmd"
        # Move the temporary file to the desired log file location
        mv $temp_file $individual_logfile
    done
}

case $flag in
"registry")
    # Registry Testnet commands
    commands=(
        "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network sepolia | tee ./reports/upgrade-logs/$timestamp/upgrade-sepolia_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network arbitrum-goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-arbitrum-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network optimism-goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-optimism-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network base-testnet | tee ./reports/upgrade-logs/$timestamp/upgrade-base-testnet_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network celo-testnet | tee ./reports/upgrade-logs/$timestamp/upgrade-celo-testnet_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network mumbai | tee ./reports/upgrade-logs/$timestamp/upgrade-mumbai_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/upgradeRegistry.ts --network pgn-sepolia | tee ./reports/upgrade-logs/$timestamp/upgrade-pgn-sepolia_$timestamp.log"
    )

    # Registry Mainnet commands
    # commands=(
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network optimism-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-optimism-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network celo-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-celo-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network arbitrum-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-arbitrum-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network base | tee ./reports/upgrade-logs/$timestamp/upgrade-base_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network polygon | tee ./reports/upgrade-logs/$timestamp/upgrade-polygon_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/upgradeRegistry.ts --network pgn-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-pgn-mainnet_$timestamp.log"
    # )

    execute_commands "${commands}"

    ;;
"allo")
    # Allo Testnet commands
    commands=(
        "bun hardhat run scripts/core/upgrades/proposeUpgradeAllo.ts --network goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network sepolia | tee ./reports/upgrade-logs/$timestamp/upgrade-sepolia_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network arbitrum-goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-arbitrum-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network optimism-goerli | tee ./reports/upgrade-logs/$timestamp/upgrade-optimism-goerli_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network base-testnet | tee ./reports/upgrade-logs/$timestamp/upgrade-base-testnet_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network celo-testnet | tee ./reports/upgrade-logs/$timestamp/upgrade-celo-testnet_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network mumbai | tee ./reports/upgrade-logs/$timestamp/upgrade-mumbai_$timestamp.log"
        # "bun hardhat run scripts/core/upgrades/upgradeAllo.ts --network pgn-sepolia | tee ./reports/upgrade-logs/$timestamp/upgrade-pgn-sepolia_$timestamp.log"
    )

    # Allo Mainnet commands
    # commands=(
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network optimism-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-optimism-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network celo-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-celo-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network arbitrum-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-arbitrum-mainnet_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network base | tee ./reports/upgrade-logs/$timestamp/upgrade-base_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network polygon | tee ./reports/upgrade-logs/$timestamp/upgrade-polygon_$timestamp.log"
    #     "bun hardhat run scripts/core/upgrades/upgradeAllo.ts --network pgn-mainnet | tee ./reports/upgrade-logs/$timestamp/upgrade-pgn-mainnet_$timestamp.log"
    # )

    execute_commands "${commands}"

    ;;
*)
    echo "Sorry, Please choose ONE!"
    ;;
esac

log "Upgrades finished with $error_count error(s)"
