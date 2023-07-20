### Networks Supported

The project has been configured to support the following networks.
All the deploy scripts will expect network param to know which network the contract deployment / interaction should take place

| network            |
|--------------------|
| `mainnet`           |
| `pgn`          |
| `optimism-mainnet` |
| `pgn-seplia`   |
| `fantom-mainnet`   |
| `fantom-testnet`   |
| `goerli`          |
| `sepolia`          |

### Setup && Install Dependencies

1. Create an `.env` file
```sh
cp ../.env.example ../.env
```

2. Create an `.env` file and fill out
    - `INFURA_ID`               : Infura ID for deploying contract ([Get one here](https://app.infura.io/dashboard))
    - `DEPLOYER_PRIVATE_KEY`    : address which deploys the contract
    - `ETHERSCAN_API_KEY`       : API key for etherscan verification ([Get one here](https://etherscan.io/myapikey))

3. Install dependencies
```shell
yarn install
```

4. Install Foundry [Install Docs](https://book.getfoundry.sh/getting-started/installation)
```shell
foundryup
```

5. Building Contracts
```shell
forge build
```

6. Running Tests

See [Testing](./TESTING.md) for more details


### Deploying Project Registry

The section here shows how to set up the project registry for the first time on a given network. Ideally these steps would be done once per chain. In this example, we would be deploying on goerli.

1. Deploy the `Registry` contract
```shell
 npx hardhat run scripts/deployRegistry.ts --network goerli  
```

### Deploying Allo

The section here shows how to deploy the Allo contract on a given network. In this example, we would be deploying on goerli.

1. Deploy the `Allo` contract
```shell
 npx hardhat run scripts/deployAllo.ts --network goerli  
```

### Contract Verification

1. Run the verify command
```shell
npx hardhat verify --network goerli <CONTRACT_ADDRESS> "<ARGS>" "<ARGS>" "<ARGS>"
```