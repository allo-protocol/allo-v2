// SPDX-License-Identifier = MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Allo} from "contracts/core/Allo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";

contract CreateProfile is Script {
    // Define the following parameters for the new profile.
    uint256 public nonce = uint256(0);
    string public name = "";
    Metadata public metadata = Metadata({protocol: uint256(0), pointer: ""});
    address public owner = address(0);
    address[] public members = [];

    function run() public {
        vm.startBroadcast();
        bytes32 profileId = _createProfile();
        vm.stopBroadcast();

        console.log("New profile created with id:");
        console.logBytes32(profileId);
    }

    function _createProfile() internal returns (bytes32 profileId) {
        Allo allo = Allo(vm.envAddress("ALLO_ADDRESS"));
        IRegistry registry = allo.getRegistry();
        profileId = registry.createProfile(nonce, name, metadata, owner, members);
    }
}
