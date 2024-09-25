# Interaction

1. Install dependencies by running `bun install`.
2. Compile contracts by running `bun smock && bun compile`.
3. Fill the necessary environment variables in `.env` file: `ALLO_ADDRESS`, `DEPLOYER_PRIVATE_KEY` and the RPC URL of the chain that will be used. You can use `.env.example` as a template.
4. Run the interaction script with:
```
bun run interaction <CHAIN> <SCRIPT_NAME>
```
For example:
```
bun run interaction sepolia CreateProfile
```

### Supported scripts

The following `<SCRIPT_NAME>` values are available:

- CreateProfile --> contract path: script/core/interaction/CreateProfile.sol
- CreatePool --> contract path: script/core/interaction/CreatePool.sol

Each script needs to be configured. Scripts parameters can be directly modified in the contracts containing the script logic. For example, in CreateProfile.sol:

```
contract CreateProfile is Script {
    // Define the following parameters for the new profile.
    uint256 public nonce = uint256(0);
    string public name = "";
    Metadata public metadata = Metadata({protocol: uint256(0), pointer: ""});
    address public owner = address(0);
    address[] public members;
```

overwrite profile parameters like so:
```
contract CreateProfile is Script {
    // Define the following parameters for the new profile.
    uint256 public nonce = 123;
    string public name = "Example Profile";
    Metadata public metadata = Metadata({protocol: uint256(1), pointer: "Metadata Pointer"});
    address public owner = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address[] public members = [0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, 0x00De4B13153673BCAE2616b67bf822500d325Fc3];
```

# Interaction with local network

1. Follow the steps 1-3 from the previous section.
2. Setup the local network just calling `anvil`
3. Run the interaction script as usual using `local` for the `<CHAIN>` parameter.

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
