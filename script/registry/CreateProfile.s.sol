// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IRegistry} from "../../contracts/core/interfaces/IRegistry.sol";

import {Metadata} from "../../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./../GoerliConfig.sol";

/// @notice This script is used to create profile test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/CreateProfile.s.sol:CreateProfile --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateProfile is Script, GoerliConfig {
    // Adding a nonce for reusability
    uint256 nonce = block.timestamp;

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    function run() external {
        // NOTE: this key matches the owner in `GoerliConfig.sol`
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Registry ==> %s", REGISTRY);

        // Prepare the members array
        address[] memory members = new address[](3);
        members[0] = address(OWNER);
        members[1] = 0xB8cEF765721A6da910f14Be93e7684e9a3714123;
        members[2] = 0xE7eB5D2b5b188777df902e89c54570E7Ef4F59CE;

        // Create a profile
        bytes32 profileId = registry.createProfile(
            nonce++, "Test Profile", Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1}), OWNER, members
        );
        IRegistry.Profile memory profile = registry.getProfileById(profileId);
        console.log("Profile created");
        console.logBytes32(profileId);
        console.log("Anchor ==> %s", profile.anchor);
    }
}
