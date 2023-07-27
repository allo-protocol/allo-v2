# Forge Testing

## Run all tests witout verbosity
```bash
yarn test

# or

forge test
```

## Run all tests with added verbosity
```bash
forge test -vvvv
```

## Run a specific test
```bash
forge test --match-test <test_name> -vvvv
```

## Run coverage report
```bash
yarn coverage:report

# or

forge coverage --report lcov
```

## Build HTML coverage report (this will inclued all solidity files)
```bash
yarn coverage:html
```

## Exclude a directory from coverage (ie: removing /test and /script from coverage)
```bash
yarn coverage:prep

# or

lcov --remove lcov.info -o lcov.info 'test/*' 'script/*'

# then run

genhtml lcov.info --branch-coverage --output-dir coverage --ignore-error category

# to generate the html report
```
