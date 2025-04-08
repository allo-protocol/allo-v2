# Allo Protocol Contracts V2

## Getting Started

```bash
git clone https://github.com/allo-protocol/allo-v2
```

### Install bun

```bash
npm install -g bun
```

### Install Dependencies

```bash
# Install Solidity dependences
forge install

# Install JS dependencies
bun install
```

> Make sure you have foundry installed globally. [Get it here](https://book.getfoundry.sh/getting-started/installation).


### Compile

```bash
bun run compile
```

### Test

```bash
bun run test 
```

### Format

```bash
bun run fmt
```


## Polkadot Compiling

- overwrite `mapping.txt` with `era.mapping.txt`
- Compile using `polkadot.hardhat.config.ts`

```
cp remappings.era.txt remappings.txt
npx hardhat compile --network westendAssetHub --config polkadot.hardhat.config.ts
```

## ZkEra Compiling

- overwrite `mapping.txt` with `era.mapping.txt`
- Compile using `polkadot.hardhat.config.ts`

```
cp remappings.era.txt remappings.txt
npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
```