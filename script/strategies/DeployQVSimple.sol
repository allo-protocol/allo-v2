// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";

contract DeployQVSimple is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");

        _contract = address(new QVSimple(_allo));
        _contractName = "QVSimpleStrategy";
    }
}
