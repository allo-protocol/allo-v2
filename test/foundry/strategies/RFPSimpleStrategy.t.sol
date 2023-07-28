pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/Allo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";
// Internal libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract RFPSimpleStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup {
    // Events
    event MaxBidIncreased(uint256 maxBid);
    event MilstoneSubmitted(uint256 milestoneId);
    event MilestoneRejected(uint256 milestoneId);
    event MilestonesSet();

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
            poolIdentity_id(),
            address(strategy),
            abi.encode(maxBid, useRegistryAnchor, metadataRequired),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("RFPSimpleStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.maxBid(), maxBid);
    }

    function test_getRecipient() public {
        address recipientId = __register_recipient();
        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(_recipient.useRegistryAnchor, useRegistryAnchor);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.RecipientStatus.Pending));
        assertEq(_recipient.proposalBid, 1e18);
    }

    function test_getRecipientStatus() public {
        address recipientId = __register_recipient();
        IStrategy.RecipientStatus recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.RecipientStatus.Pending));
    }

    function test_getPayouts() public {
        _register_allocate_submit_distribute();
        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(new address[](0), "", pool_admin());
        assertEq(payouts[0].amount, 1e18);
        assertEq(payouts[0].recipientAddress, recipientAddress());
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(pool_admin()));
        assertFalse(strategy.isValidAllocator(address(this)));
    }

    function test_getMilestoneStatus() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.RecipientStatus.Pending));
    }

    function test_setMilestone_getMilestone() public {
        __setMilestones();
        RFPSimpleStrategy.Milestone memory milestones0 = strategy.getMilestone(0);
        RFPSimpleStrategy.Milestone memory milestones1 = strategy.getMilestone(1);

        assertEq(uint8(milestones0.milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));
        assertEq(uint8(milestones1.milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));

        assertEq(milestones0.amountPercentage, 7e17);
        assertEq(milestones1.amountPercentage, 3e17);
    }

    function testRevert_setMilestone_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

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
            milestoneStatus: IStrategy.RecipientStatus.Pending
        });
        milestones[0] = milestone;
        vm.prank(pool_admin());
        strategy.setMilestones(milestones);
    }

    function test_submitUpcomingMilestone() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        RFPSimpleStrategy.Milestone memory milestone = strategy.getMilestone(0);
        assertEq(uint8(milestone.milestoneStatus), uint8(IStrategy.RecipientStatus.Pending));
    }

    function testRevert_submitUpcomingMilestone_UNAUTHORIZED() public {
        vm.expectRevert(RFPSimpleStrategy.UNAUTHORIZED.selector);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        vm.prank(makeAddr("not_recipient"));
        strategy.submitUpcomingMilestone(metadata);
    }

    function testRevert_submitUpcomingMilestone_INVALID_MILESTONE() public {
        _register_allocate_submit_distribute();

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
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
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
        emit MilestoneRejected(0);
        vm.prank(pool_admin());
        strategy.rejectMilestone(0);
        RFPSimpleStrategy.Milestone memory milestone = strategy.getMilestone(0);
        assertEq(uint8(milestone.milestoneStatus), uint8(IStrategy.RecipientStatus.Rejected));
    }

    function testRevert_rejectMilestone_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        strategy.rejectMilestone(0);
    }

    function test_rejectMilestone_MILESTONE_ALREADY_ACCEPTED() public {
        _register_allocate_submit_distribute();
        vm.expectRevert(RFPSimpleStrategy.MILESTONE_ALREADY_ACCEPTED.selector);
        vm.prank(pool_admin());
        strategy.rejectMilestone(0);
    }

    function test_withdraw() public {
        allo().fundPool{value: 1e18}(poolId, 1e18);
        vm.startPrank(pool_admin());
        strategy.setPoolActive(false);
        strategy.withdraw(9.9e17); // 1e18 - 1e17 fee = 9.9e17
        assertEq(address(allo()).balance, 0);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_BaseStrategy_POOL_ACTIVE() public {
        vm.expectRevert(IStrategy.BaseStrategy_POOL_ACTIVE.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function test_registerRecipient() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress(), false, 1e18, metadata);

        vm.expectEmit(true, false, false, true);
        emit Registered(sender, data, sender);

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        RFPSimpleStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.RecipientStatus.Pending));
    }

    function testRevert_registerRecipient_BaseStrategy_POOL_INACTIVE() public {
        __register_setMilestones_allocate();
        vm.expectRevert(IStrategy.BaseStrategy_POOL_INACTIVE.selector);
        __register_recipient();
    }

    function testRevert_registerRecipient_withUseRegistryAnchor_UNAUTHORIZED() public {
        // TODO
    }

    function testRevert_registerRecipient_withoutUseRegistryAnchor_UNAUTHORIZED() public {
        // TODO
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 0, pointer: ""});

        bytes memory data = abi.encode(recipientAddress(), false, 1e18, metadata);

        vm.expectRevert(RFPSimpleStrategy.INVALID_METADATA.selector);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_EXCEEDING_MAX_BID() public {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress(), false, 1e19, metadata);

        vm.expectRevert(RFPSimpleStrategy.EXCEEDING_MAX_BID.selector);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function test_allocate() public {
        address recipientId = __register_setMilestones_allocate();
        IStrategy.RecipientStatus recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.RecipientStatus.Accepted));
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        strategy.allocate(abi.encode(recipientAddress()), recipient());
    }

    function testRevert_allocate_BaseStrategy_POOL_INACTIVE() public {
        address recipientId = __register_setMilestones_allocate();
        vm.expectRevert(IStrategy.BaseStrategy_POOL_INACTIVE.selector);
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));
    }

    function testRevert_allocate_INVALID_RECIPIENT() public {
        // TODO
    }

    function test_distribute() public {
        _register_allocate_submit_distribute();
        assertEq(uint8(strategy.getMilestoneStatus(0)), uint8(IStrategy.RecipientStatus.Accepted));
    }

    function testRevert_distribute_UNAUTHORIZED() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_owner"));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_BaseStrategy_POOL_ACTIVE() public {
        vm.expectRevert(IStrategy.BaseStrategy_POOL_ACTIVE.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_INVALID_MILESTONE() public {
        _register_allocate_submit_distribute();

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());

        vm.expectRevert(RFPSimpleStrategy.INVALID_MILESTONE.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function testRevert_distribute_NOT_ENOUGH_FUNDS() public {
        __register_setMilestones_allocate_submitUpcomingMilestone();
        __setMilestones();
        vm.expectRevert(RFPSimpleStrategy.NOT_ENOUGH_FUNDS.selector);
        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }

    function __register_recipient() internal returns (address recipientId) {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress(), false, 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);
    }

    function __setMilestones() internal {
        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](2);
        RFPSimpleStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 7e17,
            milestoneStatus: IStrategy.RecipientStatus.Pending
        });
        RFPSimpleStrategy.Milestone memory milestone2 = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 3e17,
            milestoneStatus: IStrategy.RecipientStatus.Pending
        });

        milestones[0] = milestone;
        milestones[1] = milestone2;

        vm.prank(address(pool_admin()));
        vm.expectEmit();
        emit MilestonesSet();
        strategy.setMilestones(milestones);
    }

    function __register_setMilestones_allocate() internal returns (address recipientId) {
        recipientId = __register_recipient();
        __setMilestones();
        vm.expectEmit();

        emit Allocated(recipientId, 1e18, NATIVE, address(pool_admin()));
        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));
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
