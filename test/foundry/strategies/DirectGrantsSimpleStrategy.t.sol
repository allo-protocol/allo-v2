// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";

// Core Contracts
import {DirectGrantsSimpleStrategy} from
    "../../../contracts/strategies/_poc/direct-grants-simple/DirectGrantsSimpleStrategy.sol";

contract DirectGrantsSimpleStrategyTest is Test, EventSetup, AlloSetup, RegistrySetupFull, Native, Errors {
    event RecipientStatusChanged(address recipientId, DirectGrantsSimpleStrategy.Status status);
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, IStrategy.Status status);
    event MilestonesSet(address recipientId, uint256 milestonesLength);
    event MilestonesReviewed(address recipientId, IStrategy.Status status);
    event TimestampsUpdated(uint128 registrationStartTime, uint128 registrationEndTime, address sender);

    DirectGrantsSimpleStrategy strategyImplementation;
    DirectGrantsSimpleStrategy strategy;
    uint256 poolId;
    address token = NATIVE;
    uint128 registrationStartTime;
    uint128 registrationEndTime;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategyImplementation = new DirectGrantsSimpleStrategy(address(allo()), "DirectGrantsSimpleStrategy");
        registrationStartTime = uint128(block.timestamp);
        registrationEndTime = uint128(block.timestamp + 10);

        vm.startPrank(allo_owner());
        allo().addToCloneableStrategies(address(strategyImplementation));
        allo().updatePercentFee(0);

        vm.stopPrank();

        address payable strategyAddress;
        (poolId, strategyAddress) = _createPool(
            true, // registryGating
            true, // metadataRequired
            true // grantAmountRequired
        );

        strategy = DirectGrantsSimpleStrategy(strategyAddress);
    }

    // =================== TESTS ===================

    function test_initialize() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(registrationStartTime, registrationEndTime, address(allo()));
        (, address payable newStrategyAddress) = _createPool(true, true, true);
        DirectGrantsSimpleStrategy newStrategy = DirectGrantsSimpleStrategy(newStrategyAddress);

        assertTrue(newStrategy.registryGating());
        assertTrue(newStrategy.metadataRequired());
        assertTrue(newStrategy.grantAmountRequired());
        assertTrue(newStrategy.allocatedGrantAmount() == 0);
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            // opposite of what it should be
            registrationEndTime,
            registrationStartTime
        );
    }

    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(registrationStartTime + 1, registrationEndTime + 1, pool_admin());

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(registrationStartTime + 1, registrationEndTime + 1);

        assertEq(strategy.registrationStartTime(), registrationStartTime + 1);
        assertEq(strategy.registrationEndTime(), registrationEndTime + 1);
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(pool_manager1()));
        assertTrue(strategy.isValidAllocator(pool_manager2()));
        assertTrue(strategy.isValidAllocator(pool_admin()));

        assertFalse(strategy.isValidAllocator(randomAddress()));
    }

    function test_registerRecipient() public {
        address recipientId = _register_recipient();

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());

        assertTrue(recipient.recipientAddress == recipient1());
        assertTrue(recipient.grantAmount == 5e17);
        assertTrue(keccak256(abi.encode(recipient.metadata.pointer)) == keccak256(abi.encode("recipient-data")));
        assertTrue(recipient.metadata.protocol == 1);
        assertTrue(recipient.recipientStatus == IStrategy.Status.Pending);
        assertTrue(recipient.milestonesReviewStatus == IStrategy.Status.Pending);
        assertTrue(recipient.useRegistryAnchor);

        IStrategy.Status status = strategy.getRecipientStatus(recipientId);
        assertTrue(uint8(status) == uint8(IStrategy.Status.Pending));
    }

    function testRevert_registerRecipient_NON_ZERO_VALUE() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 0; // grant amount required and no grant amount
        Metadata memory metadata = Metadata(1, "recipient-data");

        vm.deal(address(allo()), 5e17);
        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));
        vm.expectRevert(NON_ZERO_VALUE.selector);

        strategy.registerRecipient{value: 5e17}(data, sender);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile2_member1(); // wrong sender
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));

        vm.expectRevert(UNAUTHORIZED.selector);

        strategy.registerRecipient(data, sender);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 5e17;
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.startPrank(address(allo()));
        // move time to registrationEndTime + 10
        vm.warp(registrationEndTime + 10);

        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);

        strategy.registerRecipient(data, sender);
        vm.stopPrank();
    }

    function test_registerRecipient_noRegistryGating() public {
        (, address payable newStrategyAddress) = _createPool(false, true, true);
        DirectGrantsSimpleStrategy newStrategy = DirectGrantsSimpleStrategy(newStrategyAddress);

        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientAddress, recipientId, grantAmount, metadata);

        vm.startPrank(address(allo()));
        newStrategy.registerRecipient(data, profile1_member1());
        vm.stopPrank();

        DirectGrantsSimpleStrategy.Recipient memory recipient = newStrategy.getRecipient(profile1_anchor());

        assertTrue(recipient.recipientAddress == recipient1());
        assertTrue(recipient.grantAmount == 5e17);
        assertTrue(keccak256(abi.encode(recipient.metadata.pointer)) == keccak256(abi.encode("recipient-data")));
        assertTrue(recipient.metadata.protocol == 1);
        assertTrue(recipient.recipientStatus == IStrategy.Status.Pending);
        assertTrue(recipient.useRegistryAnchor);
    }

    function testRevert_registerRecipient_noRegistryGating_UNAUTHORIZED() public {
        (, address payable newStrategyAddress) = _createPool(false, true, true);
        DirectGrantsSimpleStrategy newStrategy = DirectGrantsSimpleStrategy(newStrategyAddress);

        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientAddress, recipientId, grantAmount, metadata);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(address(allo()));
        newStrategy.registerRecipient(data, profile2_member1());
        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_REGISTRATION() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 0; // grant amount required and no grant amount
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));

        vm.expectRevert(INVALID_REGISTRATION.selector);

        strategy.registerRecipient(data, sender);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 5e17; // grant amount required and no grant amount
        Metadata memory metadata = Metadata(0, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));

        vm.expectRevert(INVALID_METADATA.selector);

        strategy.registerRecipient(data, sender);

        metadata = Metadata(1, "");
        data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.expectRevert(INVALID_METADATA.selector);

        strategy.registerRecipient(data, sender);

        vm.stopPrank();
    }

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept();
        recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.startPrank(address(allo()));

        vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);

        strategy.registerRecipient(data, sender);
        vm.stopPrank();
    }

    function test_getPayouts() public {
        address recipientId = _register_recipient_allocate_accept();
        address[] memory recipients = new address[](2);
        recipients[0] = recipientId;
        recipients[1] = randomAddress();

        bytes[] memory data = new bytes[](2);

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, data);
        assertTrue(payouts[0].amount == 1e18);
        assertTrue(payouts[0].recipientAddress == recipient1());

        assertTrue(payouts[1].amount == 0);
        assertTrue(payouts[1].recipientAddress == address(0));
    }

    function test_setRecipientStatusToInReview() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview);

        vm.startPrank(pool_manager1());
        strategy.setRecipientStatusToInReview(recipients);
        IStrategy.Status status = strategy.getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));

        vm.stopPrank();
    }

    function test_setRecipientStatusToInReview_forAcceptedApplication() public {
        address recipientId = _register_recipient_allocate_accept();
        assertEq(strategy.allocatedGrantAmount(), 1e18);

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview);

        vm.startPrank(pool_manager1());
        strategy.setRecipientStatusToInReview(recipients);
        IStrategy.Status status = strategy.getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));
        assertEq(strategy.allocatedGrantAmount(), 0);

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertTrue(recipient.grantAmount == 0);

        vm.stopPrank();
    }

    function test_isPoolActive() public {
        vm.expectEmit(false, false, false, true);
        emit PoolActive(true);

        vm.startPrank(pool_manager1());
        strategy.setPoolActive(true);
        assertTrue(strategy.isPoolActive());

        vm.expectEmit(false, false, false, true);
        emit PoolActive(false);

        vm.startPrank(pool_manager1());
        strategy.setPoolActive(false);
        assertFalse(strategy.isPoolActive());

        vm.stopPrank();
    }

    function test_allocate_accept() public {
        address recipientId = _register_recipient_allocate_accept();
        assertEq(strategy.allocatedGrantAmount(), 1e18);

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);

        assertTrue(recipient.grantAmount == 1e18);
        assertTrue(recipient.recipientStatus == IStrategy.Status.Accepted);
    }

    function test_allocate_reject() public {
        address recipientId = _register_recipient_allocate_reject();

        DirectGrantsSimpleStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);

        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Rejected));
    }

    function testRevert_allocate_NON_ZERO_VALUE() public {
        address recipientId = _register_recipient();
        DirectGrantsSimpleStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = 2e18; // 2 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);
        vm.deal(address(allo()), 2e18);
        vm.expectRevert(NON_ZERO_VALUE.selector);

        vm.startPrank(address(allo()));
        strategy.allocate{value: 1e18}(data, pool_manager1());
        vm.stopPrank();
    }

    function testRevert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT() public {
        address recipientId = _register_recipient();
        DirectGrantsSimpleStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = 2e18; // 2 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectRevert(DirectGrantsSimpleStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function testRevert_allocate_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = 1e18; // 1 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONES_ALREADY_SET.selector);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function test_setMilestonesByPoolManager() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_pool_manager();

        IStrategy.Status milestoneStatus1 = strategy.getMilestoneStatus(recipientId, 0);
        IStrategy.Status milestoneStatus2 = strategy.getMilestoneStatus(recipientId, 1);

        assertEq(uint8(milestoneStatus1), uint8(IStrategy.Status.None));
        assertEq(uint8(milestoneStatus2), uint8(IStrategy.Status.None));

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Accepted));
    }

    function test_setMilestonesByRecipient() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();

        IStrategy.Status milestoneStatus1 = strategy.getMilestoneStatus(recipientId, 0);
        IStrategy.Status milestoneStatus2 = strategy.getMilestoneStatus(recipientId, 1);

        assertEq(uint8(milestoneStatus1), uint8(IStrategy.Status.None));
        assertEq(uint8(milestoneStatus2), uint8(IStrategy.Status.None));

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_setMilestones_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept();
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);
        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.startPrank(randomAddress());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_reviewSetMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();
        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());

        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));

        vm.expectEmit(false, false, false, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Rejected);

        vm.startPrank(pool_manager1());
        strategy.reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();

        recipient = strategy.getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Rejected));

        vm.startPrank(pool_manager1());

        vm.expectEmit(false, false, false, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted);

        strategy.reviewSetMilestones(recipientId, IStrategy.Status.Accepted);
        vm.stopPrank();

        recipient = strategy.getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_reviewSetMilestones_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        strategy.reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_pool_manager();
        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONES_ALREADY_SET.selector);
        vm.startPrank(pool_manager1());
        strategy.reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept();
        vm.startPrank(pool_manager1());
        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);
        strategy.reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    function testRevert_setMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONES_ALREADY_SET.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function testRevert_setMilestones_RECIPIENT_NOT_ACCEPTED() public {
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(randomAddress(), milestones);
        vm.stopPrank();
    }

    function testRevert_setMilestones_INVALID_MILESTONE_exceed_percentage() public {
        address recipientId = _register_recipient_allocate_accept();
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18, // > 100%
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18, // > 100%
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_setMilestones_by_overriding_existing_milestones() public {
        address recipientId = _register_recipient_allocate_accept();
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](3);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[2] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.4e18,
            metadata: Metadata(1, "milestone-3"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.startPrank(profile1_member1());

        // set to 100%
        strategy.setMilestones(recipientId, milestones);

        DirectGrantsSimpleStrategy.Milestone[] memory setMilestones = strategy.getMilestones(recipientId);
        assertEq(setMilestones.length, 3);

        // Override with new milestones

        DirectGrantsSimpleStrategy.Milestone[] memory anotherMilestones = new DirectGrantsSimpleStrategy.Milestone[](1);

        anotherMilestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 1e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        // set to 100% again => should override older setting
        strategy.setMilestones(recipientId, anotherMilestones);

        // check if sum of milestones are equal to 100% (1e18)
        setMilestones = strategy.getMilestones(recipientId);

        uint256 totalAllocated = 0;

        for (uint256 i; i < setMilestones.length; i++) {
            totalAllocated += setMilestones[i].amountPercentage;
        }

        assertEq(totalAllocated, 1e18);
        assertEq(setMilestones.length, 1);

        vm.stopPrank();
    }

    function testRevert_setMilestones_INVALID_MILESTONE_wrong_status() public {
        address recipientId = _register_recipient_allocate_accept();
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.Accepted // wrong status
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_submitMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = strategy.getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Pending));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.Status.Pending));
    }

    function testRever_submitMilestones_RECIPIENT_NOT_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_reject();

        Metadata memory metadata2 = Metadata(1, "milestone-2");

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector);
        vm.startPrank(profile1_member1());
        strategy.submitMilestone(recipientId, 1, metadata2);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_pool_manager();

        Metadata memory metadata = Metadata(1, "milestone-1");

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        strategy.submitMilestone(recipientId, 0, metadata);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_pool_manager();

        Metadata memory metadata = Metadata(3, "milestone-3");

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(profile1_member1());
        strategy.submitMilestone(recipientId, 3, metadata);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        Metadata memory metadata = Metadata(1, "milestone-1");

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONE_ALREADY_ACCEPTED.selector);

        vm.startPrank(profile1_member1());
        strategy.submitMilestone(recipientId, 0, metadata);
        vm.stopPrank();
    }

    function test_rejectMilestone() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        vm.startPrank(pool_manager1());
        strategy.rejectMilestone(recipientId, 0);
        vm.stopPrank();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = strategy.getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Rejected));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_rejectMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONE_ALREADY_ACCEPTED.selector);

        vm.startPrank(pool_manager1());
        strategy.rejectMilestone(recipientId, 0);
        vm.stopPrank();
    }

    function testRevert_rejectMilestones_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();
        vm.startPrank(pool_manager1());
        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);
        strategy.rejectMilestone(recipientId, 10);
        vm.stopPrank();
    }

    function test_distribute() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = strategy.getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Accepted));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.Status.Accepted));

        assertEq(recipient1().balance, 1e18);
        assertEq(address(strategy).balance, 0);
    }

    function testRevert_distribute_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        vm.startPrank(pool_manager1());
        strategy.rejectMilestone(recipientId, 0);

        address[] memory recipients = new address[](2);

        recipients[0] = recipientId;
        recipients[1] = recipientId;

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        allo().distribute(poolId, recipients, "");
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(pool_manager1());
        strategy.setPoolActive(false);
        strategy.withdraw(1e18);
        vm.stopPrank();

        assertEq(address(strategy).balance, 0);
    }

    // =================== Helper ===================

    function _createPool(bool _registryGating, bool _metadataRequired, bool _grantAmountRequired)
        internal
        returns (uint256 newPoolId, address payable strategyClone)
    {
        vm.deal(pool_admin(), 1e18);

        vm.startPrank(pool_admin());

        newPoolId = allo().createPool{value: 1e18}(
            poolProfile_id(),
            address(strategyImplementation),
            abi.encode(
                _registryGating, _metadataRequired, _grantAmountRequired, registrationStartTime, registrationEndTime
            ),
            token,
            1e18,
            Metadata(1, "pool-data"),
            pool_managers()
        );
        vm.stopPrank();

        strategyClone = payable(address(allo().getPool(newPoolId).strategy));
    }

    function _register_recipient_return_data() internal returns (address recipientId, bytes memory data) {
        recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.startPrank(address(allo()));

        vm.expectEmit(false, false, false, true);
        emit Registered(recipientId, data, profile1_member1());

        strategy.registerRecipient(data, sender);
        vm.stopPrank();
    }

    function _register_recipient() internal returns (address recipientId) {
        (recipientId,) = _register_recipient_return_data();
    }

    function _register_recipient_allocate_accept() internal returns (address recipientId) {
        recipientId = _register_recipient();
        DirectGrantsSimpleStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = 1e18; // 1 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectEmit(false, false, true, true);

        emit RecipientStatusChanged(recipientId, recipientStatus);
        emit Allocated(recipientId, grantAmount, token, pool_manager1());

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function _register_recipient_allocate_reject() internal returns (address recipientId) {
        recipientId = _register_recipient();
        DirectGrantsSimpleStrategy.Status recipientStatus = IStrategy.Status.Rejected;
        uint256 grantAmount = 0;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectEmit(false, false, false, true);

        emit RecipientStatusChanged(recipientId, recipientStatus);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_milestones_by_pool_manager()
        internal
        returns (address recipientId)
    {
        recipientId = _register_recipient_allocate_accept();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);
        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectEmit(false, false, false, true);

        emit MilestonesSet(recipientId, milestones.length);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_milestones_by_recipient() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);
        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectEmit(false, false, false, true);

        emit MilestonesSet(recipientId, milestones.length);

        vm.startPrank(profile1_member1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept_set_milestones_by_pool_manager();

        Metadata memory metadata1 = Metadata(1, "milestone-1");
        Metadata memory metadata2 = Metadata(1, "milestone-2");

        vm.expectEmit(false, false, false, true);
        emit MilestoneSubmitted(recipientId, 0, metadata1);

        vm.startPrank(profile1_member1());
        strategy.submitMilestone(recipientId, 0, metadata1);
        strategy.submitMilestone(recipientId, 1, metadata2);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones_distribute()
        internal
        returns (address recipientId)
    {
        recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        address[] memory recipients = new address[](2);

        recipients[0] = recipientId;
        recipients[1] = recipientId;

        vm.expectEmit(false, false, true, true);

        emit MilestoneStatusChanged(recipientId, 1, IStrategy.Status.Accepted);
        emit Distributed(recipientId, recipient1(), 0.7e18, pool_manager1());

        vm.startPrank(pool_manager1());
        allo().distribute(poolId, recipients, "");

        vm.stopPrank();
    }
}
