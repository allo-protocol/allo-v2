// SPDX-License-Identifier = MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Allo} from "contracts/core/Allo.sol";

contract CreatePool is Script {
    // Define the following parameters for the new pool.
    bool public cloneStrategy = true;
    uint256 public msgValue = uint256(0);
    bytes32 public profileId = bytes32(0);
    address public strategy = address(0);
    bytes public initStrategyData = "";
    address public token = address(0);
    uint256 public amount = uint256(0);
    Metadata public metadata = Metadata({protocol: uint256(0), pointer: ""});
    address[] public managers;

    function run() public {
        vm.startBroadcast();
        uint256 poolId = _createPool();
        vm.stopBroadcast();

        console.log("New pool created with id: %s", poolId);
    }

    function _createPool() internal returns (uint256 poolId) {
        Allo allo = Allo(vm.envAddress("ALLO_ADDRESS"));
        if (cloneStrategy) {
            poolId = allo.createPool{value: msgValue}(
                profileId, strategy, initStrategyData, token, amount, metadata, managers
            );
        } else {
            poolId = allo.createPoolWithCustomStrategy{value: msgValue}(
                profileId, strategy, initStrategyData, token, amount, metadata, managers
            );
        }
    }
}
