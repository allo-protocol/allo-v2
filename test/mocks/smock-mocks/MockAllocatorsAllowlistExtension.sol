// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {AllocatorsAllowlistExtension} from "contracts/strategies/extensions/allocate/AllocatorsAllowlistExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract MockAllocatorsAllowlistExtension is BaseStrategy, AllocatorsAllowlistExtension {
    constructor(address _allo, string memory _strategyName) BaseStrategy(_allo, _strategyName) {}

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

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return super._isValidAllocator(_allocator);
    }

    function _addAllocator(address _allocator) internal virtual override {
        super._addAllocator(_allocator);
    }

    function _removeAllocator(address _allocator) internal virtual override {
        super._removeAllocator(_allocator);
    }

    function _checkOnlyPoolManager(address _sender) internal view virtual override {
        super._checkOnlyPoolManager(_sender);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal override {}

    function _distribute(address[] memory, bytes memory, address) internal override {}

    function _register(address[] memory, bytes memory, address) internal override returns (address[] memory) {}
}
