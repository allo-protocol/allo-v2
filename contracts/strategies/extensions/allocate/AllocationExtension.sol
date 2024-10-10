// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

abstract contract AllocationExtension is BaseStrategy, IAllocationExtension {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The start time for allocations
    uint64 public allocationStartTime;
    /// @notice The end time for allocations
    uint64 public allocationEndTime;

    /// @notice Defines if the strategy is sending Metadata struct in the data parameter
    bool public isUsingAllocationMetadata;

    /// @notice token -> isAllowed
    mapping(address => bool) public allowedTokens;

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice This initializes the Alocation Extension
    /// @dev This function MUST be called by the 'initialize' function in the strategy.
    /// @param _allowedTokens The allowed tokens
    /// @param _allocationStartTime The start time for the allocation period
    /// @param _allocationEndTime The end time for the allocation period
    /// @param _isUsingAllocationMetadata Defines if the strategy is sending Metadata struct in the data parameter
    function __AllocationExtension_init(
        address[] memory _allowedTokens,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        bool _isUsingAllocationMetadata
    ) internal virtual {
        if (_allowedTokens.length == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        } else {
            for (uint256 i; i < _allowedTokens.length; i++) {
                allowedTokens[_allowedTokens[i]] = true;
            }
        }

        isUsingAllocationMetadata = _isUsingAllocationMetadata;

        _updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if allocation has ended
    /// @dev Reverts if allocation has not ended
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// @notice Modifier to check if allocation is active
    /// @dev Reverts if allocation is not active
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if allocation has started
    /// @dev Reverts if allocation has started
    modifier onlyBeforeAllocation() {
        _checkBeforeAllocation();
        _;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view virtual returns (bool);

    /// @notice Returns TRUE if the token is allowed
    /// @param _token The token to check
    /// @return 'true' if the token is allowed, otherwise 'false'
    function _isAllowedToken(address _token) internal view virtual returns (bool) {
        // all tokens allowed
        if (allowedTokens[address(0)]) return true;

        if (allowedTokens[_token]) return true;

        return false;
    }

    /// @notice Sets the start and end dates for allocation.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) internal virtual {
        if (_allocationStartTime > _allocationEndTime) revert AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS();

        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit AllocationTimestampsUpdated(_allocationStartTime, _allocationEndTime, msg.sender);
    }

    /// @dev Ensure the function is called before allocation start time
    function _checkBeforeAllocation() internal virtual {
        if (block.timestamp >= allocationStartTime) revert AllocationExtension_ALLOCATION_HAS_ALREADY_STARTED();
    }

    /// @dev Ensure the function is called during allocation times
    function _checkOnlyActiveAllocation() internal virtual {
        if (block.timestamp < allocationStartTime) revert AllocationExtension_ALLOCATION_NOT_ACTIVE();
        if (block.timestamp > allocationEndTime) revert AllocationExtension_ALLOCATION_NOT_ACTIVE();
    }

    /// @dev Ensure the function is called after allocation start time
    function _checkOnlyAfterAllocation() internal virtual {
        if (block.timestamp <= allocationEndTime) revert AllocationExtension_ALLOCATION_HAS_NOT_ENDED();
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Sets the start and end dates for allocation.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)
        external
        virtual
        onlyPoolManager(msg.sender)
    {
        _updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }
}
