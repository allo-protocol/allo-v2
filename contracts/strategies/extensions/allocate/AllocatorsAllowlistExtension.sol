// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
import {AllocationExtension} from "contracts/strategies/extensions/allocate/AllocationExtension.sol";
import {IAllocatorsAllowlistExtension} from "contracts/strategies/extensions/allocate/IAllocatorsAllowlistExtension.sol";

abstract contract AllocatorsAllowlistExtension is AllocationExtension, IAllocatorsAllowlistExtension {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @dev allocator => isAllowed
    mapping(address => bool) public allowedAllocators;

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return allowedAllocators[_allocator];
    }

    /// @dev Mark an address as valid allocator
    /// @param _allocator The allocator address to add
    function _addAllocator(address _allocator) internal virtual {
        allowedAllocators[_allocator] = true;
    }

    /// @dev Remove an address from the valid allocators
    /// @param _allocator The allocator address to remove
    function _removeAllocator(address _allocator) internal virtual {
        allowedAllocators[_allocator] = false;
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Add allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocators The allocator addresses
    function addAllocators(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length; i++) {
            _addAllocator(_allocators[i]);
        }

        emit AllocatorsAdded(_allocators, msg.sender);
    }

    /// @notice Remove allocators
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocators The allocator addresses
    function removeAllocators(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length; i++) {
            _removeAllocator(_allocators[i]);
        }

        emit AllocatorsRemoved(_allocators, msg.sender);
    }
}
