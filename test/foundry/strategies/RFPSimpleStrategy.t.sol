pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";

import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

contract RFPSimpleStrategyTest is Test, Accounts, RegistrySetupFull, AlloSetup {
    // Events
    event MAX_BID_INCREASED(uint256 maxBid);
    event MILESTONE_SUBMITTED(uint256 milestoneId);
    event MILESTONE_REJECTED(uint256 milestoneId);
    event MILESTONES_SET();

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));
    }

    function test_deployment() public {}

    function test_initialize() public {}

    function test_getRecipient() public {}

    function test_getRecipientStatus() public {}

    function test_getPayouts() public {}

    function test_isValidAllocator() public {}

    function test_getMilestoneStatus() public {}

    function test_setMilestone() public {}

    function testRevert_setMilestone_UNAUTHORIZED() public {}

    function testRevert_setMilestone_MILESTONES_ALREADY_SET() public {}

    function testRevert_setMilestone_INVALID_MILESTONE() public {}

    function test_submitMilestone() public {}

    function testRevert_submitMilestone_UNAUTHORIZED() public {}

    function testRevert_submitMilestone_INVALID_MILESTONE() public {}

    function test_increaseMaxBid() public {}

    function testRevert_increaseMaxBid_UNAUTHORIZED() public {}

    function testRevert_increaseMaxBid_AMOUNT_TOO_LOW() public {}

    function test_rejectMilestone() public {}

    function testRevert_rejectMilestone_UNAUTHORIZED() public {}

    function test_rejectMilestone_MILESTONE_ALREADY_ACCEPTED() public {}

    function test_withdraw() public {}

    function test_withdraw_UNAUTHORIZED() public {}

    function test_registerRecipient() public {}

    function testRevert_registerRecipient_BaseStrategy_POOL_INACTIVE() public {}

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {}

    function testRevert_registerRecipient_withUseRegistryAnchor_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_withoutUseRegistryAnchor_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_INVALID_METADATA() public {}

    function testRevert_registerRecipient_EXCEED_MAX_BID() public {}

    function test_allocate() public {}

    function testRevert_allocate_UNAUTHORIZED() public {}

    function testRevert_allocate_INVALID_RECIPIENT() public {}

    function test_distribute() public {}

    function testRevert_distribute_UNAUTHORIZED() public {}

    function testRevert_distribute_INVALID_RECIPIENT() public {}

    function testRevert_distribute_INVALID_MILESTONE() public {}
}
