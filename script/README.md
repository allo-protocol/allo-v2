# Strategy deployment scripts

This folder contains the scripts neccessary to deploy strategies to the blockchain.

# Usage

1. Install dependencies by running `bun install`.
2. Compile contracts by running `bun smock && bun compile`.
3. Fill the necessary environment variables in `.env` file. You can use `.env.example` as a template.
4. Run the deployment script with:
```
script/strategies/deployStrategy.sh ${CHAIN_NAME} ${STRATEGY_NAME}
```
For example:
```
script/strategies/deployStrategy.sh sepolia DirectAllocation
```

# Deployment to local network

1. Follow the steps 1-3 from the previous section.
2. Setup the local network just calling `anvil`
3. Run the deployment script with:
```
script/strategies/deployStrategy.sh local ${STRATEGY_NAME}
```

# Supported networks

-   fuji
-   sepolia
-   celo-testnet
-   arbitrum-sepolia
-   optimism-sepolia
-   optimism-mainnet
-   celo-mainnet
-   arbitrum-mainnet
-   base
-   polygon
-   mainnet
-   avalanche
-   scroll
-   ftmTestnet
-   fantom
-   filecoin-mainnet
-   filecoin-calibration
-   sei-devnet
-   sei-mainnet
-   lukso-testnet
-   lukso-mainnet
-   zkSyncTestnet
-   zkSyncMainnet
-   local

# Supported strategy names

- DirectAllocation
- DonationVotingMerkleDistribution
- DonationVotingOffchain
- DonationVotingOnchain
- EasyRPGF
- QVImpactStream
- QVSimple
- RFPSimple

# Deployment to zkSync

1. Install [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
2. Deploy as usual

For actions other than deployments, such as running tests or compiling contracts, run `forge` commands using `--zksync`.