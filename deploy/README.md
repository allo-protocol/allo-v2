# Overview

The scripts in the folder are meant to deploy the core contracts on zkSync. Ensure the contracts are compiled using the `era.hardhat.config.ts` file

## Compile

```javascript
// Overwrite remapping for era
cp remappings.era.txt remappings.txt
npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
```