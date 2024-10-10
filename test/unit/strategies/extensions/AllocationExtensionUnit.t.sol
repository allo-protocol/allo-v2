// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockAllocationExtension} from "test/smock/MockMockAllocationExtension.sol";
import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";

contract AllocationExtension is Test {
    MockMockAllocationExtension extension;

    event AllocationTimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);

    function setUp() public {
        extension = new MockMockAllocationExtension(address(0), "MockAllocationExtension");
    }

    function test___AllocationExtension_initWhenAllowedTokensArrayIsEmpty() external {
        extension.call___AllocationExtension_init(new address[](0), 0, 0, false);

        // It should mark address zero as true
        assertTrue(extension.allowedTokens(address(0)));
    }

    function test___AllocationExtension_initWhenAllowedTokensArrayIsNotEmpty(address[] memory _tokens) external {
        for (uint256 i; i < _tokens.length; i++) {
            vm.assume(_tokens[i] != address(0));
        }

        extension.call___AllocationExtension_init(_tokens, 0, 0, false);

        // It should mark the tokens in the array as true
        for (uint256 i; i < _tokens.length; i++) {
            assertTrue(extension.allowedTokens(_tokens[i]));
        }
    }

    function test___AllocationExtension_initShouldSetIsUsingAllocationMetadata(bool _isUsingAllocationMetadata)
        external
    {
        extension.call___AllocationExtension_init(new address[](0), 0, 0, _isUsingAllocationMetadata);

        // It should set isUsingAllocationMetadata
        assertEq(extension.isUsingAllocationMetadata(), _isUsingAllocationMetadata);
    }

    function test___AllocationExtension_initShouldCall_updateAllocationTimestamps(
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external {
        extension.mock_call__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);

        // It should call _updateAllocationTimestamps
        extension.expectCall__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);

        extension.call___AllocationExtension_init(new address[](0), _allocationStartTime, _allocationEndTime, false);
    }

    function test__isAllowedTokenWhenAllTokensAllowed(address _tokenToCheck) external {
        // Send empty array to allow all tokens
        extension.call___AllocationExtension_init(new address[](0), 0, 0, false);

        // It should always return true
        assertTrue(extension.call__isAllowedToken(_tokenToCheck));
    }

    function test__isAllowedTokenWhenTheTokenSentIsAllowed(address _tokenToCheck) external {
        vm.assume(_tokenToCheck != address(0));

        // Send array with only that token
        address[] memory tokens = new address[](1);
        tokens[0] = _tokenToCheck;

        extension.call___AllocationExtension_init(tokens, 0, 0, false);

        // It should return true
        assertTrue(extension.call__isAllowedToken(_tokenToCheck));
    }

    function test__isAllowedTokenWhenTheTokenSentIsNotAllowed(address _tokenToCheck, address[] memory _allowedTokens)
        external
    {
        vm.assume(_allowedTokens.length > 0);
        for (uint256 i; i < _allowedTokens.length; i++) {
            vm.assume(_allowedTokens[i] != address(0));
            vm.assume(_allowedTokens[i] != _tokenToCheck);
        }

        extension.call___AllocationExtension_init(_allowedTokens, 0, 0, false);

        // It should return false
        assertFalse(extension.call__isAllowedToken(_tokenToCheck));
    }

    function test__updateAllocationTimestampsRevertWhen_StartTimeIsBiggerThanEndTime(
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external {
        vm.assume(_allocationStartTime > _allocationEndTime);

        // It should revert
        vm.expectRevert(IAllocationExtension.AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS.selector);

        extension.call__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }

    function test__updateAllocationTimestampsWhenTimesAreCorrect(uint64 _allocationStartTime, uint64 _allocationEndTime)
        external
    {
        vm.assume(_allocationStartTime < _allocationEndTime);

        // It should emit event
        vm.expectEmit();
        emit AllocationTimestampsUpdated(_allocationStartTime, _allocationEndTime, address(this));

        extension.call__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);

        // It should update start and end time
        assertEq(extension.allocationStartTime(), _allocationStartTime);
        assertEq(extension.allocationEndTime(), _allocationEndTime);
    }

    function test__checkBeforeAllocationRevertWhen_TimestampIsBiggerOrEqualThanStartTime(
        uint64 _timestamp,
        uint64 _allocationStartTime
    ) external {
        vm.assume(_timestamp >= _allocationStartTime);

        extension.call___AllocationExtension_init(new address[](0), _allocationStartTime, _allocationStartTime, false);
        vm.warp(_timestamp);

        // It should revert
        vm.expectRevert(IAllocationExtension.AllocationExtension_ALLOCATION_HAS_ALREADY_STARTED.selector);

        extension.call__checkBeforeAllocation();
    }

    function test__checkOnlyActiveAllocationRevertWhen_TimestampIsSmallerThanStartTime(
        uint64 _timestamp,
        uint64 _allocationStartTime
    ) external {
        vm.assume(_timestamp < _allocationStartTime);

        extension.call___AllocationExtension_init(new address[](0), _allocationStartTime, _allocationStartTime, false);
        vm.warp(_timestamp);

        // It should revert
        vm.expectRevert(IAllocationExtension.AllocationExtension_ALLOCATION_NOT_ACTIVE.selector);

        extension.call__checkOnlyActiveAllocation();
    }

    function test__checkOnlyActiveAllocationRevertWhen_TimestampIsBiggerThanEndTime(
        uint64 _timestamp,
        uint64 _allocationEndTime
    ) external {
        vm.assume(_timestamp > _allocationEndTime);

        extension.call___AllocationExtension_init(new address[](0), _allocationEndTime, _allocationEndTime, false);
        vm.warp(_timestamp);

        // It should revert
        vm.expectRevert(IAllocationExtension.AllocationExtension_ALLOCATION_NOT_ACTIVE.selector);

        extension.call__checkOnlyActiveAllocation();
    }

    function test__checkOnlyAfterAllocationRevertWhen_TimestampIsSmallerOrEqualThanEndTime(
        uint64 _timestamp,
        uint64 _allocationEndTime
    ) external {
        vm.assume(_timestamp <= _allocationEndTime);

        extension.call___AllocationExtension_init(new address[](0), _allocationEndTime, _allocationEndTime, false);
        vm.warp(_timestamp);

        // It should revert
        vm.expectRevert(IAllocationExtension.AllocationExtension_ALLOCATION_HAS_NOT_ENDED.selector);

        extension.call__checkOnlyAfterAllocation();
    }

    function test_UpdateAllocationTimestampsGivenSenderIsPoolManager(
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external {
        extension.mock_call__checkOnlyPoolManager(address(this));
        extension.mock_call__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);

        // It should call _updateAllocationTimestamps
        extension.expectCall__updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);

        extension.updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }
}
