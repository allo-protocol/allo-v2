// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {AllocationExtension} from "contracts/extensions/contracts/AllocationExtension.sol";
import {CoreBaseStrategy} from "contracts/strategies/CoreBaseStrategy.sol";

/// @dev This mock allows smock to override the functions of AllocationExtension abstract contract
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

    function __AllocationExtension_init(
        address[] memory _allowedTokens,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        bool _isUsingAllocationMetadata
    ) internal override virtual {
        super.__AllocationExtension_init(_allowedTokens, _allocationStartTime, _allocationEndTime, _isUsingAllocationMetadata);
    }

    function _isAllowedToken(address _token) internal view override virtual returns (bool) {
        return super._isAllowedToken(_token);
    }

    function _updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) internal override virtual {
        super._updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }

    function _checkBeforeAllocation() internal override virtual {
        super._checkBeforeAllocation();
    }

    function _checkOnlyActiveAllocation() internal override virtual {
        super._checkOnlyActiveAllocation();
    }

    function _checkOnlyAfterAllocation() internal override virtual {
        super._checkOnlyAfterAllocation();
    }

    function _checkOnlyPoolManager(address _sender) internal view override virtual {
        super._checkOnlyPoolManager(_sender);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal override {}

    function _distribute(address[] memory, bytes memory, address) internal override {}

    function _isValidAllocator(address) internal view override returns (bool) {}

    function _register(address[] memory, bytes memory, address) internal override returns (address[] memory) {}
}
