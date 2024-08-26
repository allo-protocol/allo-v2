// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAllocationExtension {
    error INVALID_ALLOCATION_TIMESTAMPS();

    error ALLOCATION_HAS_STARTED();

    error ALLOCATION_NOT_ACTIVE();

    error ALLOCATION_NOT_ENDED();

    /// @notice Emitted when the allocation timestamps are updated
    /// @param allocationStartTime The start time for the allocation period
    /// @param allocationEndTime The end time for the allocation period
    /// @param sender The sender of the transaction
    event AllocationTimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);
}
