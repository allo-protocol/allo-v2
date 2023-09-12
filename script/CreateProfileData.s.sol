// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {IRegistry} from "../contracts/core/interfaces/IRegistry.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";

contract CreateProfileData is Script {
    // adding a nonce for reusability
    uint256 nonce = block.timestamp;

    // Initialize Registry Interface
    IRegistry registry = IRegistry(0xAEc621EC8D9dE4B524f4864791171045d6BBBe27);

    function createProfile() external returns (bytes32) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address owner = vm.addr(deployerPrivateKey);

        // Create a profile
        address[] memory members = new address[](1);
        members[0] = address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42);

        bytes32 profileId = registry.createProfile(
            nonce++, "Test Profile", Metadata({protocol: 1, pointer: "TestProfileMetadata"}), owner, members
        );

        return profileId;
    }
}
