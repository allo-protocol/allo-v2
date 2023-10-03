pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create pool test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/rfp-simple/CreateRFPSimplePool.s.sol:CreateRFPSimplePool --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateRFPSimplePool is Script, Native, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create A Pool using Donation Voting Merkle Distribution V1
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(NATIVE);

        Metadata memory metadata = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        address[] memory managers = new address[](1);
        managers[0] = address(OWNER);

        // Initialize prams
        bytes memory initParams = abi.encode(10e18, false, false);

        allo.createPool{value: 1e16}(
            TEST_PROFILE_2, RFPSIMPLESTRATEGYFORCLONE, initParams, NATIVE, 1e16, metadata, managers
        );

        vm.stopBroadcast();
    }
}

// struct InitializeParams {
//         uint256 maxBid;
//         bool useRegistryAnchor;
//         bool metadataRequired;
//     }
