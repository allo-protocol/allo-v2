// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract RFPSimpleStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    // Events
    event MilestoneStatusChanged(uint256 milestoneId, IStrategy.Status status);

    bool public useRegistryAnchor;
    bool public metadataRequired;

    address[] public allowedTokens;

    RFPSimpleStrategy public strategy;

    address public token;

    Metadata public poolMetadata;

    uint256 public poolId;

    uint256 public maxBid;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = false;
        metadataRequired = true;

        maxBid = 1e18;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(maxBid, useRegistryAnchor, metadataRequired),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("RFPSimpleStrategy")));
    }

    function test_initialize() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(1337, abi.encode(maxBid, useRegistryAnchor, metadataRequired));
        assertEq(testStrategy.getPoolId(), 1337);
        assertEq(testStrategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(testStrategy.metadataRequired(), metadataRequired);
        assertEq(testStrategy.maxBid(), maxBid);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(1337, abi.encode(maxBid, useRegistryAnchor, metadataRequired));

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(1337, abi.encode(maxBid, useRegistryAnchor, metadataRequired));
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        testStrategy.initialize(1337, abi.encode(maxBid, useRegistryAnchor, metadataRequired));
    }

    function test_getRecipient() public {
        address recipientId = __register_recipient();
        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(_recipient.useRegistryAnchor, useRegistryAnchor);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Pending));
        assertEq(_recipient.proposalBid, 1e18);
    }

    function test_getRecipient_Rejected() public {
        address rejectedAddress = randomAddress();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, rejectedAddress);

        // accepted recipient
        address recipientId = __register_recipient();
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId, 1e18), address(pool_admin()));

        RFPSimpleStrategy.Recipient memory rejectedRecipient = strategy.getRecipient(rejectedAddress);
        assertEq(uint8(rejectedRecipient.recipientStatus), uint8(IStrategy.Status.Rejected));
        assertEq(rejectedRecipient.proposalBid, 1e18);
    }

    function test_getRecipient_None() public {
        // set accepted recipient
        address recipientId = __register_recipient();
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId, 1e18), address(pool_admin()));

        RFPSimpleStrategy.Recipient memory noRecipient = strategy.getRecipient(randomAddress());
        assertEq(uint8(noRecipient.recipientStatus), uint8(IStrategy.Status.None));
        assertEq(noRecipient.proposalBid, 0);
    }

    function test_getRecipientStatus() public {
        address recipientId = __register_recipient();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function test_getPayouts() public {
        _register_allocate_submit_distribute();
        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(new address[](0), new bytes[](0));
        assertEq(payouts[0].amount, 1e18);
        assertEq(payouts[0].recipientAddress, recipientAddress());
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(pool_admin()));
        assertFalse(strategy.isValidAllocator(address(this)));
    }

    function test_getMilestoneStatus() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.Status.Pending));
    }

    function testRevert_setMilestone_INVALID_MILESTONE_zeroPercentage() public {
        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](2);
        RFPSimpleStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 0,
            milestoneStatus: IStrategy.Status.Pending
        });
        RFPSimpleStrategy.Milestone memory milestone2 = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 1e18,
            milestoneStatus: IStrategy.Status.Pending
        });

        milestones[0] = milestone;
        milestones[1] = milestone2;

        vm.prank(address(pool_admin()));
        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);
        strategy.setMilestones(milestones);
    }

    function test_setMilestone_getMilestone() public {
        __setMilestones();
        RFPSimpleStrategy.Milestone memory milestones0 = strategy.getMilestone(0);
        RFPSimpleStrategy.Milestone memory milestones1 = strategy.getMilestone(1);

        assertEq(uint8(milestones0.milestoneStatus), uint8(IStrategy.Status.None));
        assertEq(uint8(milestones1.milestoneStatus), uint8(IStrategy.Status.None));

        assertEq(milestones0.amountPercentage, 7e17);
        assertEq(milestones1.amountPercentage, 3e17);
    }

    function testRevert_setMilestone_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](0);
        vm.prank(makeAddr("not_pool_admin"));
        strategy.setMilestones(milestones);
    }

    function testRevert_setMilestone_MILESTONES_ALREADY_SET() public {
        _register_allocate_submit_distribute();
        vm.expectRevert(RFPSimpleStrategy.MILESTONES_ALREADY_SET.selector);

        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](0);
        vm.prank(pool_admin());
        strategy.setMilestones(milestones);
    }

    function testRevert_setMilestone_INVALID_MILESTONE() public {
        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);

        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](1);
        RFPSimpleStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 7e17,
            milestoneStatus: IStrategy.Status.Pending
        });
        milestones[0] = milestone;
        vm.prank(pool_admin());
        strategy.setMilestones(milestones);
    }

    function test_submitUpcomingMilestone() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        RFPSimpleStrategy.Milestone memory milestone = strategy.getMilestone(0);
        assertEq(uint8(milestone.milestoneStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_submitUpcomingMilestone_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        vm.prank(makeAddr("not_recipient"));
        strategy.submitUpcomingMilestone(metadata);
    }

    function testRevert_submitUpcomingMilestone_INVALID_MILESTONE() public {
        _register_allocate_submit_distribute();

        vm.prank(recipient());
        strategy.submitUpcomingMilestone(Metadata({protocol: 1, pointer: "metadata"}));

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());

        vm.prank(recipient());
        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);
        strategy.submitUpcomingMilestone(Metadata({protocol: 1, pointer: "metadata"}));
    }

    function test_increaseMaxBid() public {
        uint256 newMaxBid = 2e18;
        vm.expectEmit();
        emit MaxBidIncreased(newMaxBid);
        vm.prank(pool_admin());
        strategy.increaseMaxBid(newMaxBid);
        assertEq(strategy.maxBid(), newMaxBid);
    }

    function testRevert_increaseMaxBid_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.increaseMaxBid(2e18);
    }

    function testRevert_increaseMaxBid_AMOUNT_TOO_LOW() public {
        vm.expectRevert(RFPSimpleStrategy.AMOUNT_TOO_LOW.selector);
        vm.prank(pool_admin());
        strategy.increaseMaxBid(0);
    }

    function test_rejectMilestone() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        vm.expectEmit();
        emit MilestoneStatusChanged(0, IStrategy.Status.Rejected);
        vm.prank(pool_admin());
        strategy.rejectMilestone(0);
        RFPSimpleStrategy.Milestone memory milestone = strategy.getMilestone(0);
        assertEq(uint8(milestone.milestoneStatus), uint8(IStrategy.Status.Rejected));
    }

    function testRevert_rejectMilestone_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.rejectMilestone(0);
    }

    function testRevert_rejectMilestone_MILESTONE_NOT_PENDING_before_submit() public {
        __register_setMilestones_allocate();

        vm.expectRevert(RFPSimpleStrategy.MILESTONE_NOT_PENDING.selector);
        vm.prank(pool_admin());
        strategy.rejectMilestone(0);
    }

    function test_rejectMilestone_MILESTONE_NOT_PENDING_after_distribution() public {
        _register_allocate_submit_distribute();
        vm.expectRevert(RFPSimpleStrategy.MILESTONE_NOT_PENDING.selector);
        vm.prank(pool_admin());
        strategy.rejectMilestone(0);
    }

    function test_setPoolActive() public {
        allo().fundPool{value: 1e18}(poolId, 1e18);
        vm.startPrank(pool_admin());
        strategy.setPoolActive(false);
        assertFalse(strategy.isPoolActive());
    }

    function testRevert_setPoolActive_UNAUTHORIZED() public {
        allo().fundPool{value: 1e18}(poolId, 1e18);
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.setPoolActive(false);
    }

    function test_withdraw() public {
        allo().fundPool{value: 1e18}(poolId, 1e18);
        vm.startPrank(pool_admin());
        strategy.setPoolActive(false);
        strategy.withdraw(NATIVE);
        assertEq(address(allo()).balance, 0);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.withdraw(NATIVE);
    }

    function testRevert_withdraw_POOL_ACTIVE() public {
        vm.expectRevert(POOL_ACTIVE.selector);
        vm.prank(pool_admin());
        strategy.withdraw(NATIVE);
    }

    function test_registerRecipient() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);

        vm.expectEmit(true, false, false, true);
        emit Registered(sender, data, sender);

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function test_registerRecipient_zero_proposalBid() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 0, metadata);

        vm.expectEmit(true, false, false, true);
        emit Registered(sender, data, sender);

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(_recipient.proposalBid, maxBid);
    }

    function test_registerRecipient_UpdatedRegistration() public {
        test_registerRecipient_zero_proposalBid();

        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 0, metadata);

        vm.expectEmit(true, false, false, true);
        emit UpdatedRegistration(sender, data, sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function test_registerRecipient_withOptionallyUsingRegistryAnchor() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        vm.prank(address(allo()));
        // no registryAnchor required
        testStrategy.initialize(1337, abi.encode(maxBid, false, metadataRequired));

        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        // optionally using anchor
        address anchor = profile1_anchor();
        bytes memory data = abi.encode(anchor, profile1_member1(), 1e18, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, profile1_member1());

        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(anchor);
        assertEq(_recipient.useRegistryAnchor, true);
    }

    function testRevert_registerRecipient_POOL_INACTIVE() public {
        __register_setMilestones_allocate();
        vm.expectRevert(POOL_INACTIVE.selector);
        __register_recipient();
    }

    function testRevert_registerRecipient_zero_recipientAddress() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(0, false, 1e18, metadata);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, sender));

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_withUseRegistryAnchor_UNAUTHORIZED() public {
        RFPSimpleStrategy testStrategy = new RFPSimpleStrategy(address(allo()), "RFPSimpleStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(1337, abi.encode(maxBid, true, metadataRequired));

        address anchor = poolProfile_anchor();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(anchor, anchor, 1e18, metadata);

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(address(allo()));
        testStrategy.registerRecipient(data, profile1_notAMember());
    }

    function testRevert_registerRecipient_withOptionallyUsingRegistryAnchor_UNAUTHORIZED() public {
        address sender = randomAddress();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(randomAddress(), sender, 1e18, metadata);

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 0, pointer: ""});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);

        vm.expectRevert(INVALID_METADATA.selector);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_EXCEEDING_MAX_BID() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e19, metadata);

        vm.expectRevert(RFPSimpleStrategy.EXCEEDING_MAX_BID.selector);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function test_allocate() public {
        address recipientId = __register_setMilestones_allocate();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        strategy.allocate(abi.encode(recipientAddress(), 1e18), recipient());
    }

    function testRevert_allocate_INVALID_AMOUNT() public {
        address recipientId = __register_recipient();
        __setMilestones();

        vm.expectRevert(Errors.INVALID.selector);
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId, 5e17), address(pool_admin()));
    }

    function testRevert_allocate_POOL_INACTIVE() public {
        address recipientId = __register_setMilestones_allocate();
        vm.expectRevert(POOL_INACTIVE.selector);
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId, 1e18), address(pool_admin()));
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, address(randomAddress())));

        strategy.allocate(abi.encode(randomAddress(), 1e18), address(pool_admin()));
    }

    function test_distribute() public {
        _register_allocate_submit_distribute();
        assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_distribute_UNAUTHORIZED() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_owner"));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_POOL_ACTIVE() public {
        vm.expectRevert(POOL_ACTIVE.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_INVALID_MILESTONE() public {
        __register_setMilestones_allocate();

        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_INVALID_MILESTONE_notPendingMilestone() public {
        test_rejectMilestone();

        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_NOT_ENOUGH_FUNDS() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        vm.expectRevert(); // Arithmetic underflow revert
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function __register_recipient() internal returns (address recipientId) {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);
    }

    function __setMilestones() internal {
        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](2);
        RFPSimpleStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 7e17,
            milestoneStatus: IStrategy.Status.None
        });
        RFPSimpleStrategy.Milestone memory milestone2 = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 3e17,
            milestoneStatus: IStrategy.Status.None
        });

        milestones[0] = milestone;
        milestones[1] = milestone2;

        vm.prank(address(pool_admin()));
        vm.expectEmit();
        emit MilestonesSet(milestones.length);
        strategy.setMilestones(milestones);
    }

    function __register_setMilestones_allocate() internal returns (address recipientId) {
        recipientId = __register_recipient();
        __setMilestones();
        vm.expectEmit();

        emit Allocated(recipientId, 1e18, NATIVE, address(pool_admin()));
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId, 1e18), address(pool_admin()));
    }

    function __register_setMilestones_allocate_submitUpcomingMilestone() internal returns (address recipientId) {
        recipientId = __register_setMilestones_allocate();
        vm.expectEmit();
        emit MilstoneSubmitted(0);
        vm.prank(recipient());
        strategy.submitUpcomingMilestone(Metadata({protocol: 1, pointer: "metadata"}));
    }

    function _register_allocate_submit_distribute() internal returns (address recipientId) {
        recipientId = __register_setMilestones_allocate_submitUpcomingMilestone();
        vm.deal(pool_admin(), 1e19);

        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);

        vm.expectEmit(true, false, false, true);
        emit Distributed(recipientId, recipientAddress(), 7e17, pool_admin());

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }
}
