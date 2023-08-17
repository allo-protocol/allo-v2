// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";

// Core Contracts
import {DirectGrantsSimpleStrategy} from
    "../../../contracts/strategies/direct-grants-simple/DirectGrantsSimpleStrategy.sol";

contract DirectGrantsSimpleStrategyTest is Test, EventSetup, AlloSetup, RegistrySetupFull, Native {
    event RecipientStatusChanged(address recipientId, DirectGrantsSimpleStrategy.InternalRecipientStatus status);
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, IStrategy.RecipientStatus status);
    event MilestonesSet(address recipientId);

    DirectGrantsSimpleStrategy strategyImplementation;
    DirectGrantsSimpleStrategy strategy;
    uint256 poolId;
    address token = NATIVE;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategyImplementation = new DirectGrantsSimpleStrategy(address(allo()), "DirectGrantsSimpleStrategy");

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
        (, address payable newStrategyAddress) = _createPool(true, true, true);
        DirectGrantsSimpleStrategy newStrategy = DirectGrantsSimpleStrategy(newStrategyAddress);

        assertTrue(newStrategy.registryGating());
        assertTrue(newStrategy.metadataRequired());
        assertTrue(newStrategy.grantAmountRequired());
        assertTrue(newStrategy.allocatedGrantAmount() == 0);
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
        assertTrue(recipient.recipientStatus == DirectGrantsSimpleStrategy.InternalRecipientStatus.Pending);
        assertTrue(recipient.useRegistryAnchor);

        IStrategy.RecipientStatus status = strategy.getRecipientStatus(recipientId);
        assertTrue(uint8(status) == uint8(IStrategy.RecipientStatus.Pending));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile2_member1(); // wrong sender
        uint256 grantAmount = 5e17; // 0.5 eth
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));

        vm.expectRevert(DirectGrantsSimpleStrategy.UNAUTHORIZED.selector);

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
        assertTrue(recipient.recipientStatus == DirectGrantsSimpleStrategy.InternalRecipientStatus.Pending);
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

        vm.expectRevert(DirectGrantsSimpleStrategy.UNAUTHORIZED.selector);

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

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_REGISTRATION.selector);

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

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_METADATA.selector);

        strategy.registerRecipient(data, sender);

        metadata = Metadata(1, "");
        data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_METADATA.selector);

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

        vm.expectRevert(DirectGrantsSimpleStrategy.RECIPIENT_ALREADY_ACCEPTED.selector);

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

    function test_setIntenalRecipientStatusToInReview() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusChanged(recipientId, DirectGrantsSimpleStrategy.InternalRecipientStatus.InReview);

        vm.startPrank(pool_manager1());
        strategy.setIntenalRecipientStatusToInReview(recipients);
        IStrategy.RecipientStatus status = strategy.getRecipientStatus(recipientId);
        assertTrue(uint8(status) == uint8(IStrategy.RecipientStatus.Pending));

        DirectGrantsSimpleStrategy.InternalRecipientStatus internalStatus =
            strategy.getInternalRecipientStatus(recipientId);
        assertTrue(uint8(internalStatus) == uint8(DirectGrantsSimpleStrategy.InternalRecipientStatus.InReview));

        vm.stopPrank();
    }

    function test_allocate_accept() public {
        address recipientId = _register_recipient_allocate_accept();
        assertEq(strategy.allocatedGrantAmount(), 1e18);

        DirectGrantsSimpleStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);

        assertTrue(recipient.grantAmount == 1e18);
        assertTrue(recipient.recipientStatus == DirectGrantsSimpleStrategy.InternalRecipientStatus.Accepted);
    }

    function test_allocate_reject() public {
        address recipientId = _register_recipient_allocate_reject();

        DirectGrantsSimpleStrategy.RecipientStatus recipientStatus = strategy.getRecipientStatus(recipientId);

        assertEq(uint8(recipientStatus), uint8(IStrategy.RecipientStatus.Rejected));
    }

    function testRevert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT() public {
        address recipientId = _register_recipient();
        DirectGrantsSimpleStrategy.InternalRecipientStatus recipientStatus =
            DirectGrantsSimpleStrategy.InternalRecipientStatus.Accepted;
        uint256 grantAmount = 2e18; // 2 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectRevert(DirectGrantsSimpleStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function testRevert_allocate_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.InternalRecipientStatus recipientStatus =
            DirectGrantsSimpleStrategy.InternalRecipientStatus.Accepted;
        uint256 grantAmount = 1e18; // 1 eth

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONES_ALREADY_SET.selector);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function test_setMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones();

        IStrategy.RecipientStatus milestoneStatus1 = strategy.getMilestoneStatus(recipientId, 0);
        IStrategy.RecipientStatus milestoneStatus2 = strategy.getMilestoneStatus(recipientId, 1);

        assertEq(uint8(milestoneStatus1), uint8(IStrategy.RecipientStatus.None));
        assertEq(uint8(milestoneStatus2), uint8(IStrategy.RecipientStatus.None));
    }

    function testRevert_setMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.RecipientStatus.None
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
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.RECIPIENT_NOT_ACCEPTED.selector);

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
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18, // > 100%
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function testRevert_setMilestones_INVALID_MILESTONE_wrong_status() public {
        address recipientId = _register_recipient_allocate_accept();
        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);

        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.RecipientStatus.Accepted // wrong status
        });

        vm.expectRevert(DirectGrantsSimpleStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_submitMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = strategy.getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));
    }

    function testRevert_submitMilestone_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones();

        Metadata memory metadata = Metadata(1, "milestone-1");

        vm.expectRevert(DirectGrantsSimpleStrategy.UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        strategy.submitMilestone(recipientId, 0, metadata);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones();

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

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.RecipientStatus.Rejected));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));
    }

    function testRevert_rejectMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        vm.expectRevert(DirectGrantsSimpleStrategy.MILESTONE_ALREADY_ACCEPTED.selector);

        vm.startPrank(pool_manager1());
        strategy.rejectMilestone(recipientId, 0);
        vm.stopPrank();
    }

    function test_distribute() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = strategy.getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.RecipientStatus.Accepted));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.RecipientStatus.Accepted));

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
            abi.encode(_registryGating, _metadataRequired, _grantAmountRequired),
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
        DirectGrantsSimpleStrategy.InternalRecipientStatus recipientStatus =
            DirectGrantsSimpleStrategy.InternalRecipientStatus.Accepted;
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
        DirectGrantsSimpleStrategy.InternalRecipientStatus recipientStatus =
            DirectGrantsSimpleStrategy.InternalRecipientStatus.Rejected;
        uint256 grantAmount = 0;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectEmit(false, false, false, true);

        emit RecipientStatusChanged(recipientId, recipientStatus);

        vm.startPrank(address(allo()));
        strategy.allocate(data, pool_manager1());
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_milestones() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept();

        DirectGrantsSimpleStrategy.Milestone[] memory milestones = new DirectGrantsSimpleStrategy.Milestone[](2);
        milestones[0] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        milestones[1] = DirectGrantsSimpleStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.RecipientStatus.None
        });

        vm.expectEmit(false, false, false, true);

        emit MilestonesSet(recipientId);

        vm.startPrank(pool_manager1());
        strategy.setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept_set_milestones();

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

        emit MilestoneStatusChanged(recipientId, 1, IStrategy.RecipientStatus.Accepted);
        emit Distributed(recipientId, recipient1(), 0.7e18, pool_manager1());

        vm.startPrank(pool_manager1());
        allo().distribute(poolId, recipients, "");

        vm.stopPrank();
    }
}
