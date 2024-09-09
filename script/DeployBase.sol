// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

abstract contract DeployBase is Script {
    function run() public {
        vm.startBroadcast();
        address _contract = _deploy();
        vm.stopBroadcast();

        console.log("Deployed contract at address: %s", _contract);
    }

    function _deploy() internal virtual returns (address _contract) {}
}
