// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {QVImpactStream} from "contracts/strategies/examples/impact-stream/QVImpactStream.sol";

contract DeployQVImpactStream is DeployBase {
    function _deploy() internal override returns (address _contract) {
        address _allo = vm.envAddress("ALLO_ADDRESS");
        return address(new QVImpactStream(_allo));
    }
}
