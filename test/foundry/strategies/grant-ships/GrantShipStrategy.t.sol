// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Strategy contracts
import {GrantShipStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";

// Internal libraries
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../../contracts/core/libraries/Native.sol";
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";
// Test libraries
import {AlloSetup} from "../../shared/AlloSetup.sol";

import {GameManagerSetup} from "./GameManagerSetup.t.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {EventSetup} from "../../shared/EventSetup.sol";

// //Todo Test if each contract inherits a different version of the same contract
// // Is this contract getting the same address that others recieve.
contract GrantShipStrategyTest is Test, GameManagerSetup, EventSetup, Errors {
    // Events
    event RecipientStatusChanged(address recipientId, GrantShipStrategy.Status status, Metadata reason);
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, IStrategy.Status status);
    event MilestonesSet(address recipientId, uint256 milestonesLength);
    event MilestonesReviewed(address recipientId, IStrategy.Status status, Metadata reason);
    event PoolFunded(uint256 poolId, uint256 amountAfterFee, uint256 feeAmount);
    event PoolWithdraw(uint256 amount);
    event FlagIssued(uint256 nonce, GrantShipStrategy.FlagType flagType, Metadata flagReason);
    event FlagResolved(uint256 nonce, Metadata resolutionReason);
    event UpdatePosted(string tag, uint256 role, address recipientId, Metadata content);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MilestoneRejected(address recipientId, uint256 milestoneId, Metadata reason);
    // ================= State ===================

    enum StopCycleAfter {
        None,
        Register,
        Allocate,
        SetMilestones,
        ApproveMilestones,
        Milestone1,
        Milestone2,
        Milestone3,
        Distribute
    }

    uint256 internal constant _grantAmount = 1_000e18;
    uint256 internal constant _poolAmount = 30_000e18;

    Metadata internal reason = Metadata(1, "reason");
    Metadata internal dummyMetadata = Metadata(1, "dummy");

    // ================= Setup =====================

    function setUp() public {
        __GameSetup();
    }

    function test() public {}

    // ================= Deployment & Init Tests =====================

    function test_ships_created() public {
        for (uint256 i = 0; i < 3;) {
            _test_ship_created(i);
            unchecked {
                i++;
            }
        }
    }

    //     // ================= GrantShip Strategy =====================

    function test_interval_distribution() public {
        // so far contracts only test spending and funding in lump sums
        // this test is to ensure that the natural distribution of funds is working as expected

        _register_recipient_allocate_accept_set_and_submit_milestones_distribute_all();
    }

    function test_whole_cycle_3_times() public {
        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 12_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 12_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 6_000e18, 1, StopCycleAfter.None);

        assertEq(ARB().balanceOf(recipient1()), _poolAmount);
        assertEq(ARB().balanceOf(address(ship(1))), 0);
        assertEq(ship(1).getPoolAmount(), 0);
    }

    function test_manyGrantees() public {
        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 4_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile2_anchor(), profile2_member1(), recipient2(), 4_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile3_anchor(), profile3_member1(), recipient3(), 6_000e18, 1, StopCycleAfter.None);

        assertEq(ARB().balanceOf(recipient1()), 4_000e18);
        assertEq(ARB().balanceOf(recipient2()), 4_000e18);
        assertEq(ARB().balanceOf(recipient3()), 6_000e18);

        assertEq(ARB().balanceOf(address(ship(1))), 16_000e18);
        assertEq(ship(1).getPoolAmount(), 16_000e18);

        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 3_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile2_anchor(), profile2_member1(), recipient2(), 2_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile3_anchor(), profile3_member1(), recipient3(), 4_000e18, 1, StopCycleAfter.None);

        assertEq(ARB().balanceOf(recipient1()), 7_000e18);
        assertEq(ARB().balanceOf(recipient2()), 6_000e18);
        assertEq(ARB().balanceOf(recipient3()), 10_000e18);

        assertEq(ARB().balanceOf(address(ship(1))), 7_000e18);
        assertEq(ship(1).getPoolAmount(), 7_000e18);

        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 2_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile3_anchor(), profile3_member1(), recipient3(), 2_000e18, 1, StopCycleAfter.None);

        assertEq(ARB().balanceOf(recipient1()), 9_000e18);
        assertEq(ARB().balanceOf(recipient2()), 6_000e18);
        assertEq(ARB().balanceOf(recipient3()), 12_000e18);

        assertEq(ARB().balanceOf(address(ship(1))), 3_000e18);
        assertEq(ship(1).getPoolAmount(), 3_000e18);

        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 3_000e18, 1, StopCycleAfter.None);

        assertEq(ARB().balanceOf(recipient1()), 12_000e18);
        assertEq(ARB().balanceOf(recipient2()), 6_000e18);
        assertEq(ARB().balanceOf(recipient3()), 12_000e18);

        assertEq(ARB().balanceOf(address(ship(1))), 0);
        assertEq(ship(1).getPoolAmount(), 0);
    }

    function test_mass_withdraw() public {
        vm.startPrank(facilitator().wearer);

        ship(0).setPoolActive(false);
        ship(1).setPoolActive(false);
        ship(2).setPoolActive(false);

        ship(0).withdraw(_poolAmount);
        ship(1).withdraw(_poolAmount);
        ship(2).withdraw(_poolAmount);

        assertEq(ARB().balanceOf(address(gameManager())), _GAME_AMOUNT);
        assertEq(ARB().balanceOf(address(ship(0))), 0);
        assertEq(ARB().balanceOf(address(ship(1))), 0);
        assertEq(ARB().balanceOf(address(ship(2))), 0);

        assertEq(ARB().balanceOf(address(gameManager())), _GAME_AMOUNT);
        assertEq(ship(0).getPoolAmount(), 0);
        assertEq(ship(1).getPoolAmount(), 0);
        assertEq(ship(2).getPoolAmount(), 0);

        gameManager().withdraw(_GAME_AMOUNT);

        assertEq(ARB().balanceOf(address(gameManager())), 0);
        assertEq(ARB().balanceOf(address(gameManager())), 0);

        assertEq(ARB().balanceOf(pool_admin()), _GAME_AMOUNT);

        vm.stopPrank();
    }

    function test_revert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT_reserved_funding() public {
        _test_grant_cycle(profile1_anchor(), profile1_member1(), recipient1(), 12_000e18, 1, StopCycleAfter.None);
        _test_grant_cycle(profile2_anchor(), profile2_member1(), recipient2(), 18_000e18, 1, StopCycleAfter.Allocate);

        bytes memory registerData = abi.encode(profile3_anchor(), recipient3(), 10_000e18, dummyMetadata);
        uint256 poolId = ship(1).getPoolId();

        vm.startPrank(profile3_member1());
        allo().registerRecipient(poolId, registerData);
        vm.stopPrank();

        bytes memory allocateData = abi.encode(profile3_anchor(), IStrategy.Status.Accepted, 10_000e18, dummyMetadata);

        vm.expectRevert(GrantShipStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);
        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, allocateData);
        vm.stopPrank();
    }

    function test_postUpdate() public {
        string memory tag = "test";
        Metadata memory metadata = Metadata(1, "Posting Update!");

        address notRecipientId = address(0);

        // Game Facilitator posts an update
        vm.expectEmit(true, true, true, true);
        emit UpdatePosted(tag, facilitator().id, notRecipientId, metadata);
        vm.startPrank(facilitator().wearer);
        ship(1).postUpdate(tag, metadata, notRecipientId);
        vm.stopPrank();

        // Recipient posts an update

        vm.expectEmit(true, true, true, true);
        emit UpdatePosted(tag, 0, profile1_anchor(), metadata);

        vm.startPrank(profile1_member1());
        ship(1).postUpdate(tag, metadata, profile1_anchor());
        vm.stopPrank();

        // Ship Operator posts an update

        vm.expectEmit(true, true, true, true);
        emit UpdatePosted(tag, shipOperator(1).id, notRecipientId, metadata);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).postUpdate(tag, metadata, notRecipientId);
        vm.stopPrank();
    }

    function testRevert_postUpdate_UNAUTHORIZED() public {
        string memory tag = "test";
        Metadata memory metadata = Metadata(1, "Posting Update!");

        address notRecipientId = address(0);

        // Random tries to post an update

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).postUpdate(tag, metadata, notRecipientId);
        vm.stopPrank();

        // Recipient tries to post an update for another recipient

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(profile1_member1());
        ship(1).postUpdate(tag, metadata, profile2_anchor());
        vm.stopPrank();

        // Ship Operator tries to post an update for another recipient
        // Doesn't use empty address flag

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).postUpdate(tag, metadata, profile2_anchor());
        vm.stopPrank();

        // Ship Operator tries to post an update with a non-zero recipientId

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).postUpdate(tag, metadata, randomAddress());
        vm.stopPrank();

        // Ship Operator tries to post an update on another ship's feed.

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(0).wearer);
        ship(1).postUpdate(tag, metadata, randomAddress());
        vm.stopPrank();
    }

    function test_isValidAllocator() public {
        assertTrue(ship(0).isValidAllocator(facilitator().wearer));
        assertTrue(ship(1).isValidAllocator(facilitator().wearer));
        assertTrue(ship(2).isValidAllocator(facilitator().wearer));

        assertFalse(ship(0).isValidAllocator(randomAddress()));

        assertFalse(ship(1).isValidAllocator(shipOperator(0).wearer));
        assertFalse(ship(2).isValidAllocator(team(0).wearer));
    }

    function test_registerRecipient() public {
        address recipientId = _register_recipient();

        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(profile1_anchor());

        assertTrue(recipient.receivingAddress == recipient1());
        assertTrue(recipient.grantAmount == _grantAmount);
        assertTrue(keccak256(abi.encode(recipient.metadata.pointer)) == keccak256(abi.encode("team recipient 1")));
        assertTrue(recipient.metadata.protocol == 1);
        assertTrue(recipient.recipientStatus == IStrategy.Status.Pending);
        assertTrue(recipient.milestonesReviewStatus == IStrategy.Status.Pending);
        assertTrue(recipient.useRegistryAnchor);

        IStrategy.Status status = ship(1).getRecipientStatus(recipientId);
        assertTrue(uint8(status) == uint8(IStrategy.Status.Pending));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        address recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile2_member1(); // wrong sender
        uint256 grantAmount = _grantAmount;
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);
        vm.startPrank(address(allo()));

        vm.expectRevert(UNAUTHORIZED.selector);

        ship(1).registerRecipient(data, sender);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept();
        recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = _grantAmount;
        Metadata memory metadata = Metadata(1, "recipient-data");

        bytes memory data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.startPrank(address(allo()));

        vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);

        ship(1).registerRecipient(data, sender);
        vm.stopPrank();
    }

    function test_getPayouts() public {
        address recipientId = _register_recipient_allocate_accept();
        address[] memory recipients = new address[](2);
        recipients[0] = recipientId;
        recipients[1] = randomAddress();

        bytes[] memory data = new bytes[](2);

        IStrategy.PayoutSummary[] memory payouts = ship(1).getPayouts(recipients, data);
        assertTrue(payouts[0].amount == _grantAmount);
        assertTrue(payouts[0].recipientAddress == recipient1());

        assertTrue(payouts[1].amount == 0);
        assertTrue(payouts[1].recipientAddress == address(0));
    }

    function test_setRecipientStatusToInReview_by_operator() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        Metadata[] memory reasons = new Metadata[](1);

        reasons[0] = reason;

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview, reason);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setRecipientStatusToInReview(recipients, reasons);
        IStrategy.Status status = ship(1).getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));

        vm.stopPrank();
    }

    function test_setRecipientStatusToInReview_by_facilitator() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        Metadata[] memory reasons = new Metadata[](1);
        reasons[0] = reason;

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview, reason);

        vm.startPrank(facilitator().wearer);
        ship(1).setRecipientStatusToInReview(recipients, reasons);
        IStrategy.Status status = ship(1).getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));

        vm.stopPrank();
    }

    function testRevert_setRecipientStatusToInReview_UNAUTHORIZED() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        Metadata[] memory reasons = new Metadata[](1);
        reasons[0] = reason;

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).setRecipientStatusToInReview(recipients, reasons);

        vm.stopPrank();
    }

    function test_setPoolActive() public {
        vm.expectEmit(true, true, true, true);
        emit PoolActive(true);

        vm.startPrank(facilitator().wearer);
        ship(1).setPoolActive(true);
        assertTrue(ship(1).isPoolActive());

        vm.expectEmit(true, true, true, true);
        emit PoolActive(false);

        vm.startPrank(facilitator().wearer);
        ship(1).setPoolActive(false);
        assertFalse(ship(1).isPoolActive());

        vm.stopPrank();
    }

    function testRevert_setPoolActive_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setPoolActive(true);
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).setPoolActive(false);
        vm.stopPrank();
    }

    function test_allocate_accept() public {
        address recipientId = _register_recipient_allocate_accept();
        assertEq(ship(1).allocatedGrantAmount(), _grantAmount);

        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(recipientId);

        assertTrue(recipient.grantAmount == _grantAmount);
        assertTrue(recipient.recipientStatus == IStrategy.Status.Accepted);
    }

    function test_allocate_reject() public {
        address recipientId = _register_recipient_allocate_reject();

        GrantShipStrategy.Status recipientStatus = ship(1).getRecipientStatus(recipientId);

        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Rejected));
    }

    function testRevert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT() public {
        address recipientId = _register_recipient();
        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _poolAmount + 5_000e18;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount, reason);

        vm.expectRevert(GrantShipStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function testRevert_allocate_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single();

        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount, reason);

        vm.expectRevert(GrantShipStrategy.MILESTONES_ALREADY_SET.selector);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function test_setMilestonesByShipOperator() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        IStrategy.Status milestoneStatus1 = ship(1).getMilestoneStatus(recipientId, 0);
        IStrategy.Status milestoneStatus2 = ship(1).getMilestoneStatus(recipientId, 1);

        assertEq(uint8(milestoneStatus1), uint8(IStrategy.Status.None));
        assertEq(uint8(milestoneStatus2), uint8(IStrategy.Status.None));

        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Accepted));
    }

    function test_setMilestonesByRecipient() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();

        IStrategy.Status milestoneStatus1 = ship(1).getMilestoneStatus(recipientId, 0);
        IStrategy.Status milestoneStatus2 = ship(1).getMilestoneStatus(recipientId, 1);

        assertEq(uint8(milestoneStatus1), uint8(IStrategy.Status.None));
        assertEq(uint8(milestoneStatus2), uint8(IStrategy.Status.None));

        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_setMilestones_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept();
        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);
        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.startPrank(randomAddress());
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function test_reviewSetMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();
        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(profile1_anchor());

        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));

        vm.expectEmit(true, true, true, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Rejected, reason);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected, reason);
        vm.stopPrank();

        recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Rejected));

        vm.startPrank(shipOperator(1).wearer);

        vm.expectEmit(true, true, true, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted, reason);

        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Accepted, reason);
        vm.stopPrank();

        recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_reviewSetMilestones_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();

        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Accepted, reason);
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected, reason);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        vm.expectRevert(GrantShipStrategy.MILESTONES_ALREADY_SET.selector);
        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected, reason);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept();

        vm.startPrank(shipOperator(1).wearer);
        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected, reason);
        vm.stopPrank();
    }

    function testRevert_setMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single();

        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(GrantShipStrategy.MILESTONES_ALREADY_SET.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function testRevert_setMilestones_RECIPIENT_NOT_ACCEPTED() public {
        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(randomAddress(), milestones, reason);
        vm.stopPrank();
    }

    function testRevert_setMilestones_INVALID_MILESTONE_exceed_percentage() public {
        address recipientId = _register_recipient_allocate_accept();
        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18, // > 100%
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18, // > 100%
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function test_setMilestones_by_overriding_existing_milestones() public {
        address recipientId = _register_recipient_allocate_accept();
        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](3);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[2] = GrantShipStrategy.Milestone({
            amountPercentage: 0.4e18,
            metadata: Metadata(1, "milestone-3"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.startPrank(profile1_member1());

        // set to 100%
        ship(1).setMilestones(recipientId, milestones, reason);

        GrantShipStrategy.Milestone[] memory setMilestones = ship(1).getMilestones(recipientId);
        assertEq(setMilestones.length, 3);

        // Override with new milestones

        GrantShipStrategy.Milestone[] memory anotherMilestones = new GrantShipStrategy.Milestone[](1);

        anotherMilestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 1e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        // set to 100% again => should override older setting
        ship(1).setMilestones(recipientId, anotherMilestones, reason);

        // check if sum of milestones are equal to 100% (1e18)
        setMilestones = ship(1).getMilestones(recipientId);

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
        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.Accepted // wrong status
        });

        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function test_submitMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        GrantShipStrategy.Milestone[] memory milestones = ship(1).getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Pending));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.Status.Pending));
    }

    function testRever_submitMilestones_RECIPIENT_NOT_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_reject();

        Metadata memory metadata2 = Metadata(1, "milestone-2");

        vm.expectRevert(RECIPIENT_NOT_ACCEPTED.selector);
        vm.startPrank(profile1_member1());
        ship(1).submitMilestone(recipientId, 1, metadata2);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        Metadata memory metadata = Metadata(1, "milestone-1");

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).submitMilestone(recipientId, 0, metadata);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        Metadata memory metadata = Metadata(3, "milestone-3");

        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);

        vm.startPrank(profile1_member1());
        ship(1).submitMilestone(recipientId, 3, metadata);
        vm.stopPrank();
    }

    function testRevert_submitMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single();

        Metadata memory metadata = Metadata(1, "milestone-1");

        vm.expectRevert(GrantShipStrategy.MILESTONE_ALREADY_ACCEPTED.selector);

        vm.startPrank(profile1_member1());
        ship(1).submitMilestone(recipientId, 0, metadata);
        vm.stopPrank();
    }

    function test_rejectMilestone() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        vm.expectEmit(true, true, true, true);
        emit MilestoneRejected(recipientId, 0, reason);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).rejectMilestone(recipientId, 0, reason);
        vm.stopPrank();

        GrantShipStrategy.Milestone[] memory milestones = ship(1).getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Rejected));
        assertEq(uint8(milestones[1].milestoneStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_rejectMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single();

        vm.expectRevert(GrantShipStrategy.MILESTONE_ALREADY_ACCEPTED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).rejectMilestone(recipientId, 0, reason);
        vm.stopPrank();
    }

    function testRevert_rejectMilestones_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();
        vm.startPrank(shipOperator(1).wearer);
        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);
        ship(1).rejectMilestone(recipientId, 10, reason);
        vm.stopPrank();
    }

    function test_distribute_single() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single();

        GrantShipStrategy.Milestone[] memory milestones = ship(1).getMilestones(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Accepted));

        assertEq(ARB().balanceOf(recipient1()), 300e18);
        assertEq(ARB().balanceOf(address(ship(1))), _poolAmount - 300e18);
        assertEq(ship(1).getPoolAmount(), _poolAmount - 300e18);
    }

    function test_distribute_all() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute_all();

        GrantShipStrategy.Milestone[] memory milestones = ship(1).getMilestones(recipientId);
        uint256 upcomingMilestone = ship(1).getUpcomingMilestone(recipientId);

        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Accepted));
        assertEq(uint8(milestones[0].milestoneStatus), uint8(IStrategy.Status.Accepted));

        assertEq(milestones.length, 2);
        assertEq(upcomingMilestone, 2);

        assertEq(ARB().balanceOf(recipient1()), _grantAmount);
        assertEq(ARB().balanceOf(address(ship(1))), _poolAmount - _grantAmount);
        assertEq(ship(1).getPoolAmount(), _poolAmount - _grantAmount);
    }

    function testRevert_distribute_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        vm.startPrank(shipOperator(1).wearer);
        ship(1).rejectMilestone(recipientId, 0, reason);

        address[] memory recipients = new address[](2);

        recipients[0] = recipientId;
        recipients[1] = recipientId;

        uint256 poolId = ship(1).getPoolId();

        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();
    }

    function test_withdraw() public {
        uint256 GM_poolId = gameManager().getPoolId();

        vm.startPrank(facilitator().wearer);

        ship(1).setPoolActive(false);

        vm.expectEmit(true, true, true, true);
        emit Approval(address(ship(1)), address(allo()), _poolAmount);
        emit Transfer(address(ship(1)), address(allo()), _poolAmount);
        emit Approval(address(allo()), address(ship(1)), 0);
        emit PoolFunded(GM_poolId, _poolAmount, 0);
        emit PoolWithdraw(_poolAmount);

        ship(1).withdraw(_poolAmount);

        vm.stopPrank();

        assertEq(ARB().balanceOf(address(ship(1))), 0);
        assertEq(ARB().balanceOf(address(gameManager())), _poolAmount);

        assertEq(ship(1).getPoolAmount(), 0);
        assertEq(gameManager().getPoolAmount(), _poolAmount);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).withdraw(_poolAmount);
        vm.stopPrank();
    }

    function testRevert_withdraw_POOL_ACTIVE() public {
        vm.expectRevert(POOL_ACTIVE.selector);

        vm.startPrank(facilitator().wearer);
        ship(1).withdraw(_poolAmount);
        vm.stopPrank();
    }

    function test_issueFlag() public {
        _issue_flag(0, GrantShipStrategy.FlagType.Red);

        GrantShipStrategy.Flag memory flag = ship(1).getFlag(0);

        assertEq(ship(1).unresolvedRedFlags(), 1);
        assertEq(uint8(flag.flagType), uint8(GrantShipStrategy.FlagType.Red));
        assertFalse(flag.isResolved);

        _issue_flag(1, GrantShipStrategy.FlagType.Yellow);

        assertEq(ship(1).unresolvedRedFlags(), 1);
    }

    function testRevert_issueFlag_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).issueFlag(0, GrantShipStrategy.FlagType.Red, reason);
        vm.stopPrank();
    }

    function testRevert_issueFlag_INVALID_FLAG() public {
        vm.expectRevert(GrantShipStrategy.INVALID_FLAG.selector);

        vm.startPrank(facilitator().wearer);
        ship(1).issueFlag(0, GrantShipStrategy.FlagType.None, reason);
        vm.stopPrank();
    }

    function testRevert_issueFlag_FLAG_ALREADY_EXISTS() public {
        _issue_flag(0, GrantShipStrategy.FlagType.Red);

        vm.expectRevert(GrantShipStrategy.FLAG_ALREADY_EXISTS.selector);

        vm.startPrank(facilitator().wearer);
        ship(1).issueFlag(0, GrantShipStrategy.FlagType.Red, reason);
        vm.stopPrank();
    }

    function test_issueFlag_stops_allocation() public {
        address recipientId = _register_recipient();

        _issue_flag(0, GrantShipStrategy.FlagType.Red);

        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _grantAmount;
        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount, reason);
        uint256 poolId = ship(1).getPoolId();

        vm.expectRevert(GrantShipStrategy.UNRESOLVED_RED_FLAGS.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        ship(1).resolveFlag(0, reason);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function test_issueFlag_stops_distribution() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        _issue_flag(0, GrantShipStrategy.FlagType.Red);

        address[] memory recipients = new address[](1);

        recipients[0] = recipientId;
        uint256 poolId = ship(1).getPoolId();

        vm.expectRevert(GrantShipStrategy.UNRESOLVED_RED_FLAGS.selector);

        vm.startPrank(shipOperator(1).wearer);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        ship(1).resolveFlag(0, reason);
        vm.stopPrank();

        vm.startPrank(shipOperator(1).wearer);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();
    }

    function test_resolveFlag() public {
        _issue_flag(0, GrantShipStrategy.FlagType.Red);

        GrantShipStrategy.Flag memory flag = ship(1).getFlag(0);

        assertEq(ship(1).unresolvedRedFlags(), 1);
        assertEq(uint8(flag.flagType), uint8(GrantShipStrategy.FlagType.Red));

        _resolve_flag(0);

        flag = ship(1).getFlag(0);

        assertEq(ship(1).unresolvedRedFlags(), 0);
        assertEq(uint8(flag.flagType), uint8(GrantShipStrategy.FlagType.Red));
        assertTrue(flag.isResolved);

        _issue_flag(1, GrantShipStrategy.FlagType.Yellow);
        GrantShipStrategy.Flag memory yellowFlag = ship(1).getFlag(1);

        assertEq(ship(1).unresolvedRedFlags(), 0);

        assertEq(uint8(yellowFlag.flagType), uint8(GrantShipStrategy.FlagType.Yellow));

        _resolve_flag(1);

        yellowFlag = ship(1).getFlag(1);

        assertEq(ship(1).unresolvedRedFlags(), 0);
        assertEq(uint8(yellowFlag.flagType), uint8(GrantShipStrategy.FlagType.Yellow));
        assertTrue(yellowFlag.isResolved);
    }

    //     // ================= Helpers =====================

    function _issue_flag(uint256 _nonce, GrantShipStrategy.FlagType _flagType) internal {
        vm.startPrank(facilitator().wearer);

        vm.expectEmit(true, true, true, true);
        emit FlagIssued(_nonce, _flagType, reason);

        ship(1).issueFlag(_nonce, _flagType, reason);
        vm.stopPrank();
    }

    function _resolve_flag(uint256 _nonce) internal {
        vm.startPrank(facilitator().wearer);

        vm.expectEmit(true, true, true, true);
        emit FlagResolved(_nonce, reason);

        ship(1).resolveFlag(_nonce, reason);
        vm.stopPrank();
    }

    function _test_ship_created(uint256 _shipId) internal {
        ShipInitData memory shipInitData = shipSetupData(_shipId);
        assertTrue(address(ship(_shipId).getAllo()) == address(allo()));
        // assertTrue(ship(_shipId).getStrategyId() == keccak256(abi.encode(shipInitData.shipName)));
        assertTrue(ship(_shipId).registryGating());
        assertTrue(ship(_shipId).metadataRequired());
        assertTrue(ship(_shipId).grantAmountRequired());
        assertTrue(shipInitData.operatorHatId == ship(_shipId).operatorHatId());
    }

    function _register_recipient_return_data() internal returns (address recipientId, bytes memory data) {
        recipientId = profile1_anchor();
        address recipientAddress = recipient1();
        address sender = profile1_member1();
        uint256 grantAmount = _grantAmount; //
        Metadata memory metadata = Metadata(1, "team recipient 1");

        data = abi.encode(recipientId, recipientAddress, grantAmount, metadata);

        vm.startPrank(address(allo()));

        vm.expectEmit(true, true, true, true);
        emit Registered(recipientId, data, profile1_member1());

        ship(1).registerRecipient(data, sender);
        vm.stopPrank();
    }

    function _register_recipient() internal returns (address recipientId) {
        (recipientId,) = _register_recipient_return_data();
    }

    function _register_recipient_allocate_accept() internal returns (address recipientId) {
        recipientId = _register_recipient();
        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount, reason);

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, recipientStatus, reason);
        emit Allocated(recipientId, grantAmount, address(ARB()), facilitator().wearer);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function _register_recipient_allocate_reject() internal returns (address recipientId) {
        recipientId = _register_recipient();
        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Rejected;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount, reason);

        vm.expectEmit(false, false, false, false);
        emit RecipientStatusChanged(recipientId, recipientStatus, reason);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_milestones_by_ship_operator()
        internal
        returns (address recipientId)
    {
        recipientId = _register_recipient_allocate_accept();

        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);
        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectEmit(true, true, true, true);

        emit MilestonesSet(recipientId, milestones.length);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted, reason);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_milestones_by_recipient() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept();

        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);
        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: Metadata(1, "milestone-1"),
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.7e18,
            metadata: Metadata(1, "milestone-2"),
            milestoneStatus: IStrategy.Status.None
        });

        vm.expectEmit(true, true, true, true);

        emit MilestonesSet(recipientId, milestones.length);

        vm.startPrank(profile1_member1());
        ship(1).setMilestones(recipientId, milestones, reason);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        Metadata memory metadata1 = Metadata(1, "milestone-1");
        Metadata memory metadata2 = Metadata(1, "milestone-2");

        vm.expectEmit(true, true, true, true);
        emit MilestoneSubmitted(recipientId, 0, metadata1);

        vm.startPrank(profile1_member1());
        ship(1).submitMilestone(recipientId, 0, metadata1);
        ship(1).submitMilestone(recipientId, 1, metadata2);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones_distribute_all()
        internal
        returns (address recipientId)
    {
        recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        address[] memory recipients = new address[](2);

        recipients[0] = recipientId;
        recipients[1] = recipientId;

        vm.expectEmit(true, true, true, true);

        emit MilestoneStatusChanged(recipientId, 1, IStrategy.Status.Accepted);
        emit Distributed(recipientId, recipient1(), 0.7e18, facilitator().wearer);

        vm.startPrank(shipOperator(1).wearer);
        allo().distribute(ship(1).getPoolId(), recipients, "");
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones_distribute_single()
        internal
        returns (address recipientId)
    {
        recipientId = _register_recipient_allocate_accept_set_and_submit_milestones();

        address[] memory recipients = new address[](1);

        recipients[0] = recipientId;
        // recipients[1] = recipientId;

        vm.expectEmit(true, true, true, true);

        emit MilestoneStatusChanged(recipientId, 0, IStrategy.Status.Accepted);
        emit Distributed(recipientId, recipient1(), 0.3e18, facilitator().wearer);

        vm.startPrank(shipOperator(1).wearer);
        allo().distribute(ship(1).getPoolId(), recipients, "");
        vm.stopPrank();
    }

    function _test_grant_cycle(
        address _granteeAnchor,
        address _granteeTeamMember,
        address _receiverAddress,
        uint256 _cycleGrantAmount,
        uint256 _shipIndex,
        StopCycleAfter _stopCycleAfter
    ) internal {
        bytes memory registerData = abi.encode(_granteeAnchor, _receiverAddress, _cycleGrantAmount, dummyMetadata);
        uint256 poolId = ship(_shipIndex).getPoolId();

        address shipOperator = shipOperator(uint32(_shipIndex)).wearer;

        vm.startPrank(_granteeTeamMember);
        allo().registerRecipient(poolId, registerData);
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.Register) {
            return;
        }

        bytes memory allocateData =
            abi.encode(_granteeAnchor, IStrategy.Status.Accepted, _cycleGrantAmount, dummyMetadata);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, allocateData);
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.Allocate) {
            return;
        }

        GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](3);

        milestones[0] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: dummyMetadata,
            milestoneStatus: IStrategy.Status.None
        });

        milestones[1] = GrantShipStrategy.Milestone({
            amountPercentage: 0.3e18,
            metadata: dummyMetadata,
            milestoneStatus: IStrategy.Status.None
        });

        milestones[2] = GrantShipStrategy.Milestone({
            amountPercentage: 0.4e18,
            metadata: dummyMetadata,
            milestoneStatus: IStrategy.Status.None
        });

        vm.startPrank(_granteeTeamMember);
        ship(_shipIndex).setMilestones(_granteeAnchor, milestones, dummyMetadata);
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.SetMilestones) {
            return;
        }

        vm.startPrank(shipOperator);
        ship(_shipIndex).reviewSetMilestones(_granteeAnchor, IStrategy.Status.Accepted, dummyMetadata);
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.ApproveMilestones) {
            return;
        }

        vm.startPrank(_granteeTeamMember);
        ship(_shipIndex).submitMilestone(_granteeAnchor, 0, dummyMetadata);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = _granteeAnchor;

        vm.startPrank(shipOperator);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.Milestone1) {
            return;
        }

        vm.startPrank(_granteeTeamMember);
        ship(_shipIndex).submitMilestone(_granteeAnchor, 1, dummyMetadata);
        vm.stopPrank();

        vm.startPrank(shipOperator);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.Milestone2) {
            return;
        }

        vm.startPrank(_granteeTeamMember);
        ship(_shipIndex).submitMilestone(_granteeAnchor, 2, dummyMetadata);
        vm.stopPrank();

        vm.startPrank(shipOperator);
        allo().distribute(poolId, recipients, "");
        vm.stopPrank();

        if (_stopCycleAfter == StopCycleAfter.Milestone3) {
            return;
        }
    }
}
