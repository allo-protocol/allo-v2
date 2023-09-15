// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../contracts/core/Allo.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";
import {Native} from "../contracts/core/libraries/Native.sol";
import {Config} from "./Config.sol";

/// @notice This script is used to create pool test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/CreatePool.s.sol:CreatePool --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreatePool is Script, Native, Config {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create A Pool using Donation Voting Merkle Distribution V1
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(NATIVE);

        bytes memory encodedStrategyData = abi.encode(
            true,
            true,
            block.timestamp + 500,
            block.timestamp + 10000,
            block.timestamp + 20000,
            block.timestamp + 30000,
            allowedTokens
        );

        Metadata memory metadata = Metadata({protocol: 1, pointer: "TestPoolMetadataPointer"});
        address[] memory managers = new address[](1);
        managers[0] = address(OWNER);

        allo.createPool{value: 1e16}(
            TEST_PROFILE_1,
            DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE,
            encodedStrategyData,
            NATIVE,
            1e16,
            metadata,
            managers
        );

        vm.stopBroadcast();
    }
}
