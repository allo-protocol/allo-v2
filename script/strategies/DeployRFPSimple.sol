// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {RFPSimple} from "contracts/strategies/examples/rfp/RFPSimple.sol";

contract DeployRFPSimple is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");

        _contract = address(new RFPSimple(_allo));
        _contractName = "RFPSimpleStrategy";
    }
}
