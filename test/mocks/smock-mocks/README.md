# Intermediary mock contracts

### What is this?

To test some functionalities of the smart contracts like internal functions and setup the test suite correctly, we need to use mock contracts. 
Those mock contracts are generated using [Smock](https://github.com/defi-wonderland/smock-foundry).
In order to expose some functions so Smock can generate the mock, we need to create intermediary contracts that inherit from the contract we want to mock.

### How to use it?

If you wish to run the tests, be sure to have installed smock and run the following command: `bun smock`. This will generate the mock contracts in the `test/smock` folder.