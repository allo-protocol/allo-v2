pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";
import {RFPCommitteeStrategy} from "../../../contracts/strategies/rfp-committee/RFPCommitteeStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract RFPCommitteeStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    // Events
    event Voted(address indexed recipientId, address voter);

    bool public useRegistryAnchor;
    bool public metadataRequired;

    address[] public allowedTokens;

    RFPCommitteeStrategy public strategy;

    address public token;

    Metadata public poolMetadata;

    uint256 public poolId;

    uint256 public maxBid;

    uint256 public voteThreshold;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = false;
        metadataRequired = true;

        maxBid = 1e18;

        voteThreshold = 2;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new RFPCommitteeStrategy(address(allo()), "RFPCommitteeStrategy");

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(voteThreshold, maxBid, useRegistryAnchor, metadataRequired),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        RFPCommitteeStrategy testStrategy = new RFPCommitteeStrategy(address(allo()), "RFPCommitteeStrategy");
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("RFPCommitteeStrategy")));
    }

    function test_initialize() public {
        RFPCommitteeStrategy testStrategy = new RFPCommitteeStrategy(address(allo()), "RFPCommitteeStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(1337, abi.encode(voteThreshold, maxBid, useRegistryAnchor, metadataRequired));
        assertEq(testStrategy.getPoolId(), 1337);
        assertEq(testStrategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(testStrategy.metadataRequired(), metadataRequired);
        assertEq(testStrategy.maxBid(), maxBid);
        assertEq(testStrategy.voteThreshold(), voteThreshold);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        RFPCommitteeStrategy testStrategy = new RFPCommitteeStrategy(address(allo()), "RFPCommitteeStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(1337, abi.encode(voteThreshold, maxBid, useRegistryAnchor, metadataRequired));

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(1337, abi.encode(voteThreshold, maxBid, useRegistryAnchor, metadataRequired));
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        RFPCommitteeStrategy testStrategy = new RFPCommitteeStrategy(address(allo()), "RFPCommitteeStrategy");
        vm.expectRevert(UNAUTHORIZED.selector);
        testStrategy.initialize(1337, abi.encode(voteThreshold, maxBid, useRegistryAnchor, metadataRequired));
    }

    function test_allocate() public {
        address recipientId = __register_setMilestones_allocate();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function test_allocate_reallocating() public {
        address recipientId = __register_recipient();
        address recipientId2 = __register_recipient2();

        __setMilestones();

        assertEq(strategy.votes(recipientId), 0);
        assertEq(strategy.votes(recipientId2), 0);

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));

        assertEq(strategy.votes(recipientId), 1);
        assertEq(strategy.votes(recipientId2), 0);
        assertEq(strategy.votedFor(address(pool_admin())), recipientId);

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId2), address(pool_admin()));

        assertEq(strategy.votes(recipientId), 0);
        assertEq(strategy.votes(recipientId2), 1);
        assertEq(strategy.votedFor(address(pool_admin())), recipientId2);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("not_pool_manager"));
        strategy.allocate(abi.encode(recipientAddress()), recipient());
    }

    function testRevert_allocate_RECIPIENT_ALREADY_ACCEPTED() public {
        __register_setMilestones_allocate();
        vm.prank(address(allo()));
        vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);
        strategy.allocate(abi.encode(randomAddress()), address(pool_admin()));
    }

    function __register_recipient() internal returns (address recipientId) {
        address sender = recipient();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);
    }

    function __register_recipient2() internal returns (address recipientId) {
        address sender = makeAddr("recipient2");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(address(0), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);
    }

    function __setMilestones() internal {
        RFPCommitteeStrategy.Milestone[] memory milestones = new RFPCommitteeStrategy.Milestone[](1);
        RFPCommitteeStrategy.Milestone memory milestone = RFPSimpleStrategy.Milestone({
            metadata: Metadata({protocol: 1, pointer: "metadata"}),
            amountPercentage: 1e18,
            milestoneStatus: IStrategy.Status.Pending
        });

        milestones[0] = milestone;

        vm.prank(address(pool_admin()));
        strategy.setMilestones(milestones);
    }

    function __register_setMilestones_allocate() internal returns (address recipientId) {
        recipientId = __register_recipient();
        __setMilestones();

        vm.expectEmit();
        emit Voted(recipientId, address(pool_admin()));

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_admin()));

        vm.expectEmit();
        emit Voted(recipientId, address(pool_manager1()));
        vm.expectEmit();
        emit Allocated(recipientId, 1e18, NATIVE, address(0));

        vm.prank(address(allo()));
        strategy.allocate(abi.encode(recipientId), address(pool_manager1()));
    }
}
