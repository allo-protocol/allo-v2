// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";

contract DeployDirectAllocation is DeployBase {
    function setUp() public {
        // Mainnet
        address _allo = 0x0000000000000000000000000000000000000000;
        _deploymentParams[1] = abi.encode(_allo);
    }

    function _deploy(uint256, bytes memory _data) internal override returns (address _contract) {
        return address(new DirectAllocationStrategy(abi.decode(_data, (address))));
    }
}
