// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockAllocatorsAllowlistExtension} from "test/smock/MockMockAllocatorsAllowlistExtension.sol";

contract AllocatorsAllowlistExtension is Test {
    MockMockAllocatorsAllowlistExtension extension;

    event AllocatorsAdded(address[] allocators, address sender);
    event AllocatorsRemoved(address[] allocators, address sender);

    function setUp() public {
        extension = new MockMockAllocatorsAllowlistExtension(address(0), "MockAllocatorsAllowlistExtension");
    }

    function test__isValidAllocatorShouldReturnTRUEOrFALSEGivenTheStatusOfTheAllocator(
        bool _isAllowed,
        address _allocator
    ) external {
        extension.call__addAllocator(_allocator);

        if (!_isAllowed) extension.call__removeAllocator(_allocator);

        // It should return TRUE or FALSE given the status of the allocator
        assertEq(extension.call__isValidAllocator(_allocator), _isAllowed);
    }

    function test__addAllocatorShouldSetToTrueTheStatusOfTheAllocator(address _allocator) external {
        extension.call__addAllocator(_allocator);

        // It should set to true the status of the allocator
        assertTrue(extension.allowedAllocators(_allocator));
    }

    function test__removeAllocatorShouldSetToFalseTheStatusOfTheAllocator(address _allocator) external {
        extension.call__addAllocator(_allocator);
        extension.call__removeAllocator(_allocator);

        // It should set to false the status of the allocator
        assertFalse(extension.allowedAllocators(_allocator));
    }

    function test_AddAllocatorsGivenSenderIsPoolManager(address[] memory _allocators) external {
        extension.mock_call__checkOnlyPoolManager(address(this));

        // It should call _addAllocator for each allocator in the list
        for (uint256 i; i < _allocators.length; i++) {
            extension.expectCall__addAllocator(_allocators[i]);
        }

        // It should emit event
        vm.expectEmit();
        emit AllocatorsAdded(_allocators, address(this));

        extension.addAllocators(_allocators);
    }

    function test_RemoveAllocatorsGivenSenderIsPoolManager(address[] memory _allocators) external {
        extension.mock_call__checkOnlyPoolManager(address(this));

        // It should call _removeAllocator for each allocator in the list
        for (uint256 i; i < _allocators.length; i++) {
            extension.expectCall__removeAllocator(_allocators[i]);
        }

        // It should emit event
        vm.expectEmit();
        emit AllocatorsRemoved(_allocators, address(this));

        extension.removeAllocators(_allocators);
    }
}
