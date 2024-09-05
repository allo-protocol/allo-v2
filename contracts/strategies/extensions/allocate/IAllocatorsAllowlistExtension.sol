// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IAllocatorsAllowlistExtension {
    /// @notice Emitted when an allocator is added
    /// @param allocators The allocator addresses
    /// @param sender The sender of the transaction
    event AllocatorsAdded(address[] allocators, address sender);

    /// @notice Emitted when an allocator is removed
    /// @param allocators The allocator addresses
    /// @param sender The sender of the transaction
    event AllocatorsRemoved(address[] allocators, address sender);

    /// @notice Returns TRUE if the allocator is allowed, FALSE otherwise
    /// @param _allocator The allocator address to check
    /// @return TRUE if the allocator is allowed, FALSE otherwise
    function allowedAllocators(address _allocator) external view returns (bool);
}
