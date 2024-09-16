# Deployment

1. Install dependencies by running `bun install`.
2. Compile contracts by running `bun smock && bun compile`.
3. Fill the necessary environment variables in `.env` file. You can use `.env.example` as a template.
4. Run the deployment script with:
```
bun run deploy-allo-v2.1 <CHAIN>
```
For example:
```
bun run deploy-allo-v2.1 sepolia
```
For more deployment [options](https://book.getfoundry.sh/reference/forge/forge-script) run with `forge script` directly:
```
forge script ${SCRIPT_CONTRACT_NAME} --fork-url ${RPC_URL} --private-key ${PRIVATE_KEY} --broadcast
```
For example:
```
forge script DeployAllo --fork-url https://eth-sepolia.public.blastapi.io --private-key 0x0000 --broadcast
```

# Deployment to local network

1. Follow the steps 1-3 from the previous section.
2. Setup the local network just calling `anvil`
3. Run the deployment script with:
```
bun run deploy-allo-v2.1 local
```

### Notes
As deployer address, anvil's default account 0 will be used. 
- Deployer address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Deployer private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

For initializing Allo, the following made-up addresses will be used:
```
owner = makeAddr("protocol owner");
treasury = makeAddr("protocol treasury");
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

# Deployment to zkSync

1. Install [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
2. Deploy as usual

For actions other than deployments, such as running tests or compiling contracts, run `forge` commands using `--zksync`.


