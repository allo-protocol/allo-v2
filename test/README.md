# Forge Testing

The tests have been written in foundry. 
For detailed information on how the testing framework works, refer https://book.getfoundry.sh/forge/tests 

#### Run all tests witout verbosity
```bash
yarn test
```

#### Run all tests with added verbosity
```bash
forge test -vvvv
```

#### Run a specific test
```bash
forge test --match-test <test_name> -vvvv
```

#### Generate coverage on terminal
```bash
yarn coverage
```

#### Generate HTML coverage report 
```bash
yarn coverage:html
```