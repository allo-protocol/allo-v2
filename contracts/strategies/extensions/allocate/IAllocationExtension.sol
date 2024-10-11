// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IAllocationExtension {
    /// @dev Error thrown when the allocation timestamps are invalid
    error AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS();

    /// @dev Error thrown when trying to call the function when the allocation has started
    error AllocationExtension_ALLOCATION_HAS_ALREADY_STARTED();

    /// @dev Error thrown when trying to call the function when the allocation is not active
    error AllocationExtension_ALLOCATION_NOT_ACTIVE();

    /// @dev Error thrown when trying to call the function when the allocation has not ended
    error AllocationExtension_ALLOCATION_HAS_NOT_ENDED();

    /// @dev Error thrown when trying to call the function when the allocation has ended
    error AllocationExtension_ALLOCATION_HAS_ENDED();

    /// @notice Emitted when the allocation timestamps are updated
    /// @param allocationStartTime The start time for the allocation period
    /// @param allocationEndTime The end time for the allocation period
    /// @param sender The sender of the transaction
    event AllocationTimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);

    /// @notice The start time for the allocation period
    /// @return allocationStartTime
    function allocationStartTime() external view returns (uint64);

    /// @notice The end time for the allocation period
    /// @return allocationEndTime
    function allocationEndTime() external view returns (uint64);

    /// @notice Defines if the strategy is sending Metadata struct in the data parameter
    /// @return TRUE if metadata is used for allocations
    function isUsingAllocationMetadata() external view returns (bool);

    /// @notice Returns TRUE if the token is allowed, FALSE otherwise
    /// @param _token address of the token to evaluate
    /// @return boolean
    function allowedTokens(address _token) external view returns (bool);

    /// @notice Sets the start and end dates for allocation.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) external;
}
