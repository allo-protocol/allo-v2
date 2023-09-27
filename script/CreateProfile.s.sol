// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {IRegistry} from "../contracts/core/interfaces/IRegistry.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";
import {Config} from "./Config.sol";

/// @notice This script is used to create profile test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/CreateProfile.s.sol:CreateProfile --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateProfile is Script, Config {
    // Adding a nonce for reusability
    uint256 nonce = block.timestamp;

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    function run() external {
        // NOTE: this key matches the owner in `Config.sol`
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Prepare the members array
        address[] memory members = new address[](1);
        members[0] = address(OWNER);

        // Create a profile
        registry.createProfile(
            nonce++, "Test Profile", Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1}), OWNER, members
        );
    }
}
