## Deployment Checklist

### 💎 Hard Requirements
- [ ] Define admin wallet.
- [ ] Define treasury wallet, (ensure Safe support).
- [ ] Make funds available for deployment (prepare funds request).
- [ ] All tests pass 🚨 No Exceptions 🚨

### 🍦 Soft Requirements
- [ ] Ensure Spec support (after decision is made on supported networks, make sure our list can be supported by spec).

### 🍱 Preparing the deployment
- [ ] Make sure all networks we are planning on supporting are set up in the `hardhat.config.ts` file.
- [ ] Check verification keys for each network.
- [ ] Setup new deployer wallet (we want the nonce to start at 0 for each network).
- [ ] Fund the deployer wallet for each network (see Fund Deployer Wallet checklist).
- [ ] Set up the treasury address for each network supported. We would like to have the same SAFE address across all networks.
- [ ] Add the treasury address to the `allo.config.ts` file.
- [ ] Initial Fee's will be set to zero (0) i.e. `percentFee` and `baseFee`.
- [ ] Add the initial owner to the `registry.config.ts` file.
- [ ] Delete the `cache_hardhat` contents.


### 💰 Fund Deployer Wallet (need gas estimate for deployment)
#### 🔗 This is the list of supported chains 🔗
- [ ] Ethereum Mainnet
- [ ] Optimism
- [ ] Base
- [ ] Arbitrum
- [ ] PGN
- [ ] Polygon
- [ ] ZKSync Era
- [ ] Celo

#### 📝 The following will need to be completed for each of the above networks:
- [ ] Fund Wallet
- [ ] Deploy
- [ ] Test deployment
- [ ] Update Graph
- [ ] Update Alloscan
- [ ] Update Spec


### 🛰️ Running the deployment (🔁 this will repeat for each network)
- [ ] Completion of all above Hard Requirements
-
- [ ] Deploy Contract Factory (except ZkEra, won't work)
- [ ] Verify Contract Factory
- [ ] Add the deployment addresses to the `deployment.config.ts` file.
-
- [ ] Deploy the Registry Contract
- [ ] Verify the Registry Contract Proxy
- [ ] Verify the Registry Contract Implementation
- [ ] Add the deployment addresses to the `registry.config.ts` file.
-
- [ ] Deploy the Allo Contract
- [ ] Verify the Allo Contract Proxy
- [ ] Verify the Allo Contract Implementation
- [ ] Add the deployment addresses to the `allo.config.ts` file.
-
- [ ] Deploy Donation Voting Merkle Direct Transfer
- [ ] Verify Donation Voting Merkle Direct Transfer
- [ ] Add to cloneable strategies
- [ ] Add the deployment addresses to the `strategies.config.ts` file.
-
- [ ] Deploy Donation Voting Merkle Vault
- [ ] Verify Donation Voting Merkle Vault
- [ ] Add to cloneable strategies
- [ ] Add the deployment addresses to the `strategies.config.ts` file.
-
- [ ] Deploy QV Simple
- [ ] Verify QV Simple
- [ ] Add to cloneable strategies
- [ ] Add the deployment addresses to the `strategies.config.ts` file.
-
- [ ] Deploy RFP Simple
- [ ] Verify RFP Simple
- [ ] Add to cloneable strategies
- [ ] Add the deployment addresses to the `strategies.config.ts` file.
-
- [ ] Deploy RFP committee
- [ ] Verify RFP committee
- [ ] Add to cloneable strategies
- [ ] Add the deployment addresses to the `strategies.config.ts` file.


### 🛑 After Deployment
- [ ] Update spec with addresses for each network
- [ ] Add contracts to allo scan for each network
- [ ] Add contracts to graph for each network - see graph checklist for graph deployment (TODO)
- [ ] Update <Contract>.md for each deployed contract
