// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {AllocationExtension} from "contracts/extensions/contracts/AllocationExtension.sol";
import {CoreBaseStrategy} from "contracts/strategies/CoreBaseStrategy.sol";

contract MockAllocationExtension is CoreBaseStrategy, AllocationExtension {
    constructor(address _allo) CoreBaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external override {
        __BaseStrategy_init(_poolId);
        (
            address[] memory _allowedTokens,
            uint64 _allocationStartTime,
            uint64 _allocationEndTime,
            bool _isUsingAllocationMetadata
        ) = abi.decode(_data, (address[], uint64, uint64, bool));
        __AllocationExtension_init(_allowedTokens, _allocationStartTime, _allocationEndTime, _isUsingAllocationMetadata);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal override {}

    function _distribute(address[] memory, bytes memory, address) internal override {}

    function _isValidAllocator(address) internal view override returns (bool) {}

    function _register(address[] memory, bytes memory, address) internal override returns (address[] memory) {}
}
