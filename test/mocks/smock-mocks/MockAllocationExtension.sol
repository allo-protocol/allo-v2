// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {AllocationExtension} from "contracts/strategies/extensions/allocate/AllocationExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

/// @dev This mock allows smock to override the functions of AllocationExtension abstract contract
contract MockAllocationExtension is BaseStrategy, AllocationExtension {
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

    function __AllocationExtension_init(
        address[] memory _allowedTokens,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        bool _isUsingAllocationMetadata
    ) internal virtual override {
        super.__AllocationExtension_init(
            _allowedTokens, _allocationStartTime, _allocationEndTime, _isUsingAllocationMetadata
        );
    }

    function _isAllowedToken(address _token) internal view virtual override returns (bool) {
        return super._isAllowedToken(_token);
    }

    function _updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)
        internal
        virtual
        override
    {
        super._updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }

    function _checkBeforeAllocation() internal virtual override {
        super._checkBeforeAllocation();
    }

    function _checkOnlyActiveAllocation() internal virtual override {
        super._checkOnlyActiveAllocation();
    }

    function _checkOnlyAfterAllocation() internal virtual override {
        super._checkOnlyAfterAllocation();
    }

    function _checkOnlyPoolManager(address _sender) internal view virtual override {
        super._checkOnlyPoolManager(_sender);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal override {}

    function _distribute(address[] memory, bytes memory, address) internal override {}

    function _isValidAllocator(address) internal view override returns (bool) {}

    function _register(address[] memory, bytes memory, address) internal override returns (address[] memory) {}
}
