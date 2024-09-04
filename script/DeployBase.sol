// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

abstract contract DeployBase is Script {
    /// @notice Deployment parameters for each chain
    mapping(uint256 _chainId => bytes _deploymentData) internal _deploymentParams;

    function run() public {
        bytes memory _params = _deploymentParams[block.chainid];

        vm.startBroadcast();
        address _contract = _deploy(block.chainid, _params);
        vm.stopBroadcast();

        console.log("Deployed contract at address: %s", _contract);
    }

    function _deploy(uint256 _chainId, bytes memory _data) internal virtual returns (address _contract) {}
}
