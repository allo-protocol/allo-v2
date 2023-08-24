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

1. Create an `.env` file and populate the .env file
```sh
cp ../.env.sample ../.env
```

2. Install dependencies
```shell
yarn install
```

3. Install Foundry [Install Docs](https://book.getfoundry.sh/getting-started/installation)
```shell
foundryup
```

4. Compile Contracts
```shell
yarn compile
```

6. Running Tests

The tests have been written in foundry.
For detailed information on how the testing framework works, refer https://book.getfoundry.sh/forge/tests

Run all tests without verbosity
```bash
yarn test
yarn test -vvvv # with verbosity
yarn test --match-test <test_name> -vvvv # specific test
```

7. Coverage

```bash
yarn coverage # generate coverage on terminal
yarn coverage:html # generage lcov coverage on html
```


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
