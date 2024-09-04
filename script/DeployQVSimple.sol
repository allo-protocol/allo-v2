// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";

contract DeployQVSimple is DeployBase {
    function setUp() public {
        // Mainnet
        address _allo = 0x0000000000000000000000000000000000000000;
        _deploymentParams[1] = abi.encode(_allo);
    }

    function _deploy(uint256, bytes memory _data) internal override returns (address _contract) {
        return address(new QVSimple(abi.decode(_data, (address))));
    }
}