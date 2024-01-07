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

//Todo Test if each contract inherits a different version of the same contract
// Is this contract getting the same address that others recieve.
contract GrantShiptStrategyTest is Test, GameManagerSetup, EventSetup, Errors {
    // Events
    event RecipientStatusChanged(address recipientId, GrantShipStrategy.Status status);
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, IStrategy.Status status);
    event MilestonesSet(address recipientId, uint256 milestonesLength);
    event MilestonesReviewed(address recipientId, IStrategy.Status status);
    event PoolFunded(uint256 poolId, uint256 amountAfterFee, uint256 feeAmount);

    // ================= State ===================

    uint256 internal constant _grantAmount = 1_000e18;
    uint256 internal constant _poolAmount = 30_000e18;

    // ================= Setup =====================

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __GameSetup();
    }

    // ================= Deployment & Init Tests =====================

    function test_deploy_manager() public {
        assertTrue(address(gameManager()) != address(0));
        assertTrue(address(gameManager().getAllo()) == address(allo()));
        assertTrue(gameManager().getStrategyId() == keccak256(abi.encode(gameManagerStrategyId)));
        assertTrue(address(hats()) == gameManager().getHatsAddress());
    }

    function test_init_manager() public {
        assertTrue(gameManager().currentRoundId() == 0);
        assertTrue(gameManager().currentRoundStartTime() == 0);
        assertTrue(gameManager().currentRoundEndTime() == 0);
        assertTrue(gameManager().currentRoundStatus() == IStrategy.Status.None);
        assertTrue(gameManager().token() == address(arbToken));
        assertTrue(gameManager().gameFacilitatorHatId() == facilitator().id);
    }

    function test_ships_created() public {
        for (uint256 i = 0; i < 3;) {
            _test_ship_created(i);
            unchecked {
                i++;
            }
        }
    }

    // ================= GrantShip Strategy =====================

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

        assertTrue(recipient.recipientAddress == recipient1());
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

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setRecipientStatusToInReview(recipients);
        IStrategy.Status status = ship(1).getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));

        vm.stopPrank();
    }

    function test_setRecipientStatusToInReview_by_facilitator() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, IStrategy.Status.InReview);

        vm.startPrank(facilitator().wearer);
        ship(1).setRecipientStatusToInReview(recipients);
        IStrategy.Status status = ship(1).getRecipientStatus(recipientId);

        assertTrue(uint8(status) == uint8(IStrategy.Status.InReview));

        vm.stopPrank();
    }

    function testRevert_setRecipientStatusToInReview_UNAUTHORIZED() public {
        address recipientId = _register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).setRecipientStatusToInReview(recipients);

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

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

        vm.expectRevert(GrantShipStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function testRevert_allocate_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);

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
        console.log("recipient.milestonesReviewStatus: ", uint8(recipient.milestonesReviewStatus));
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));
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
        ship(1).setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_reviewSetMilestones() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();
        GrantShipStrategy.Recipient memory recipient = ship(1).getRecipient(profile1_anchor());

        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Pending));

        vm.expectEmit(true, true, true, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Rejected);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();

        recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Rejected));

        vm.startPrank(shipOperator(1).wearer);

        vm.expectEmit(true, true, true, true);
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted);

        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Accepted);
        vm.stopPrank();

        recipient = ship(1).getRecipient(profile1_anchor());
        assertEq(uint8(recipient.milestonesReviewStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_reviewSetMilestones_UNAUTHORIZED() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();

        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Accepted);
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_MILESTONES_ALREADY_SET() public {
        address recipientId = _register_recipient_allocate_accept_set_milestones_by_ship_operator();

        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Accepted);
        vm.stopPrank();

        vm.expectRevert(GrantShipStrategy.MILESTONES_ALREADY_SET.selector);
        vm.startPrank(shipOperator(1).wearer);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    function testRevert_reviewSetMilestones_INVALID_MILESTONE() public {
        address recipientId = _register_recipient_allocate_accept();
        vm.startPrank(shipOperator(1).wearer);
        vm.expectRevert(GrantShipStrategy.INVALID_MILESTONE.selector);
        ship(1).reviewSetMilestones(recipientId, IStrategy.Status.Rejected);
        vm.stopPrank();
    }

    //Todo Debug with a clearer head.

    // function testRevert_setMilestones_MILESTONES_ALREADY_SET() public {
    //     address recipientId = _register_recipient_allocate_accept_set_and_submit_milestones_distribute();

    //     GrantShipStrategy.Milestone[] memory milestones = new GrantShipStrategy.Milestone[](2);

    //     milestones[0] = GrantShipStrategy.Milestone({
    //         amountPercentage: 0.3e18,
    //         metadata: Metadata(1, "milestone-1"),
    //         milestoneStatus: IStrategy.Status.None
    //     });

    //     milestones[1] = GrantShipStrategy.Milestone({
    //         amountPercentage: 0.7e18,
    //         metadata: Metadata(1, "milestone-2"),
    //         milestoneStatus: IStrategy.Status.None
    //     });

    //     vm.expectRevert(GrantShipStrategy.MILESTONES_ALREADY_SET.selector);

    //     vm.startPrank(shipOperator(1).wearer);
    //     ship(1).setMilestones(recipientId, milestones);
    //     vm.stopPrank();
    // }

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
        ship(1).setMilestones(randomAddress(), milestones);
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
        ship(1).setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function test_register_recipient_allocate_accept_set_milestones_by_pool_manager() public {
        _register_recipient_allocate_accept_set_milestones_by_ship_operator();
    }

    function test_register_recipient_allocate_accept_set_milestones_by_recipient() public {
        _register_recipient_allocate_accept_set_milestones_by_recipient();
    }

    function test_register_recipient_allocate_accept_set_and_submit_milestones() public {
        _register_recipient_allocate_accept_set_and_submit_milestones();
    }

    function test_register_recipient_allocate_accept_set_and_submit_milestones_distribute() public {
        _register_recipient_allocate_accept_set_and_submit_milestones_distribute();
    }

    // ================= Helpers =====================

    function _test_ship_created(uint256 _shipId) internal {
        // GrantShipStrategy shipStrategy = _getShipStrategy(_shipId);
        ShipInitData memory shipInitData = abi.decode(shipSetupData(_shipId), (ShipInitData));
        assertTrue(address(ship(_shipId).getAllo()) == address(allo()));
        assertTrue(ship(_shipId).getStrategyId() == keccak256(abi.encode(shipInitData.shipName)));
        assertTrue(ship(_shipId).registryGating());
        assertTrue(ship(_shipId).metadataRequired());
        assertTrue(ship(_shipId).grantAmountRequired());
        assertTrue(shipInitData.operatorHatId == ship(_shipId).operatorHatId());
        // Todo add tests for other params once they are added to Ship Strategy
    }

    function _getShipStrategy(uint256 _shipId) internal view returns (GrantShipStrategy) {
        address payable strategyAddress = gameManager().getShipAddress(_shipId);
        return GrantShipStrategy(strategyAddress);
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

    function _quick_fund_ship(uint256 _shipId) internal {
        vm.prank(arbWhale);
        ARB().transfer(facilitator().wearer, 30_000e18);

        uint256 poolId = ship(_shipId).getPoolId();

        vm.startPrank(facilitator().wearer);
        ARB().approve(address(allo()), 30_000e18);

        allo().fundPool(poolId, 30_000e18);

        vm.stopPrank();
    }

    function _register_recipient_allocate_accept() internal returns (address recipientId) {
        recipientId = _register_recipient();
        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Accepted;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);
        _quick_fund_ship(1);

        vm.expectEmit(true, true, true, true);
        emit RecipientStatusChanged(recipientId, recipientStatus);
        emit Allocated(recipientId, grantAmount, address(ARB()), facilitator().wearer);

        vm.startPrank(address(allo()));
        ship(1).allocate(data, facilitator().wearer);
        vm.stopPrank();
    }

    function _register_recipient_allocate_reject() internal returns (address recipientId) {
        recipientId = _register_recipient();
        GrantShipStrategy.Status recipientStatus = IStrategy.Status.Rejected;
        uint256 grantAmount = _grantAmount;

        bytes memory data = abi.encode(recipientId, recipientStatus, grantAmount);
        _quick_fund_ship(1);

        console.log("----------IN TEST----------");
        console.log("recipientId: ", recipientId);
        console.log("recipientStatus: ", uint8(recipientStatus));
        vm.expectEmit(false, false, false, false);
        emit RecipientStatusChanged(recipientId, recipientStatus);

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
        emit MilestonesReviewed(recipientId, IStrategy.Status.Accepted);

        vm.startPrank(shipOperator(1).wearer);
        ship(1).setMilestones(recipientId, milestones);
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
        ship(1).setMilestones(recipientId, milestones);
        vm.stopPrank();
    }

    function _register_recipient_allocate_accept_set_and_submit_milestones() internal returns (address recipientId) {
        recipientId = _register_recipient_allocate_accept_set_milestones_by_recipient();

        Metadata memory metadata1 = Metadata(1, "milestone-1");
        Metadata memory metadata2 = Metadata(1, "milestone-2");

        vm.expectEmit(true, true, true, true);
        emit MilestoneSubmitted(recipientId, 0, metadata1);

        vm.startPrank(profile1_member1());
        ship(1).submitMilestone(recipientId, 0, metadata1);
        ship(1).submitMilestone(recipientId, 1, metadata2);
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

        vm.expectEmit(true, true, true, true);

        emit MilestoneStatusChanged(recipientId, 1, IStrategy.Status.Accepted);
        emit Distributed(recipientId, recipient1(), 0.7e18, facilitator().wearer);

        vm.startPrank(facilitator().wearer);
        allo().distribute(ship(1).getPoolId(), recipients, "");

        vm.stopPrank();
    }
}
