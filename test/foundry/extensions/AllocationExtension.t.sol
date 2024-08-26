// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

contract AllocationExtension is Test {
    function test___AllocationExtension_initWhenAllowedTokensArrayIsEmpty() external {
        // It should mark address zero as true
        vm.skip(true);
    }

    function test___AllocationExtension_initWhenAllowedTokensArrayIsNotEmpty() external {
        // It should mark the tokens in the array as true
        vm.skip(true);
    }

    function test___AllocationExtension_initShouldSetIsUsingAllocationMetadata() external {
        // It should set isUsingAllocationMetadata
        vm.skip(true);
    }

    function test___AllocationExtension_initShouldCall_updateAllocationTimestamps() external {
        // It should call _updateAllocationTimestamps
        vm.skip(true);
    }

    function test__isAllowedTokenWhenAllTokensAllowed() external {
        // It should always return true
        vm.skip(true);
    }

    function test__isAllowedTokenWhenTheTokenSentIsAllowed() external {
        // It should return true
        vm.skip(true);
    }

    function test__isAllowedTokenWhenTheTokenSentIsNotAllowed() external {
        // It should return false
        vm.skip(true);
    }

    function test__updateAllocationTimestampsRevertWhen_StartTimeIsBiggerThanEndTime() external {
        // It should revert
        vm.skip(true);
    }

    function test__updateAllocationTimestampsWhenTimesAreCorrect() external {
        // It should update start and end time
        // It should emit event
        vm.skip(true);
    }

    function test__checkBeforeAllocationRevertWhen_TimestampIsBiggerThanStartTime() external {
        // It should revert
        vm.skip(true);
    }

    function test__checkOnlyActiveAllocationRevertWhen_TimestampIsSmallerThanStartTime() external {
        // It should revert
        vm.skip(true);
    }

    function test__checkOnlyActiveAllocationRevertWhen_TimestampIsBiggerThanEndTime() external {
        // It should revert
        vm.skip(true);
    }

    function test__checkOnlyAfterAllocationRevertWhen_TimestampIsSmallerOrEqualThanEndTime() external {
        // It should revert
        vm.skip(true);
    }

    function test_UpdateAllocationTimestampsGivenSenderIsPoolManager() external {
        // It should call _updateAllocationTimestamps
        vm.skip(true);
    }
}
