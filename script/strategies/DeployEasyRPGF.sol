// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {EasyRPGF} from "contracts/strategies/examples/easy-rpgf/EasyRPGF.sol";

contract DeployEasyRPGF is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");

        _contract = address(new EasyRPGF(_allo));
        _contractName = "EasyRPGFStrategy";
    }
}
