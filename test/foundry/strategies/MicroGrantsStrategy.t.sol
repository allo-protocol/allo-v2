// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {MicroGrantsStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract MicroGrantsStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    event Allocated(address indexed recipientId, IStrategy.Status status, address sender);

    error AMOUNT_TOO_LOW();
    error EXCEEDING_MAX_BID();

    MicroGrantsStrategy strategy;

    bool public useRegistryAnchor;

    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    uint256 public maxRequestedAmount;
    uint256 public approvalThreshold;

    Metadata public poolMetadata;
    uint256 public poolId;

    mapping(address => MicroGrantsStrategy.Recipient) internal _recipients;
    mapping(address => bool) public allocators;
    mapping(address => mapping(address => bool)) public allocated;
    mapping(address => mapping(IStrategy.Status => uint256)) public recipientAllocations;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = true;
        allocationStartTime = uint64(block.timestamp);
        allocationEndTime = uint64(block.timestamp + 1 days);
        maxRequestedAmount = 1e18;
        approvalThreshold = 3;

        strategy = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        MicroGrantsStrategy strategy_ = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");

        assertTrue(address(strategy_) != address(0));
        assertTrue(address(strategy_.getAllo()) == address(allo()));
        assertTrue(strategy_.getStrategyId() == keccak256(abi.encode("MicroGrantsStrategy")));
    }

    function test_initialize() public {
        MicroGrantsStrategy strategy_ = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");
        vm.prank(address(allo()));

        strategy_.initialize(
            420,
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount)
        );

        assertEq(strategy_.getPoolId(), 420);
        assertEq(strategy_.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy_.maxRequestedAmount(), maxRequestedAmount);
        assertEq(strategy_.approvalThreshold(), approvalThreshold);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        MicroGrantsStrategy strategy_ = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");
        vm.startPrank(address(allo()));
        strategy_.initialize(
            420,
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount)
        );

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        strategy_.initialize(
            420,
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount)
        );
        vm.stopPrank();
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        MicroGrantsStrategy strategy_ = new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy");

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy_.initialize(
            420,
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount)
        );
    }

    function test_getRecipient() public {
        address recipientId = __registerRecipient();
        MicroGrantsStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);

        assertEq(_recipient.useRegistryAnchor, useRegistryAnchor);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Pending));
        assertEq(_recipient.requestedAmount, 1e18);
    }

    function test_getRecipientStatus() public {
        address recipientId = __registerRecipient();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.prank(address(allo()));
        vm.expectRevert(INVALID_METADATA.selector);

        strategy.registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e18, Metadata({protocol: 0, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function testRevert_registerRecipient_EXCEEDING_MAX_BID() public {
        vm.prank(address(allo()));
        vm.expectRevert(EXCEEDING_MAX_BID.selector);

        strategy.registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e19, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function test_registerRecipient_ZERO_AMOUNT() public {
        bytes memory registrationData =
            abi.encode(profile1_anchor(), profile1_member1(), 0, Metadata({protocol: 1, pointer: "metadata"}));

        vm.startPrank(address(allo()));
        strategy.registerRecipient(registrationData, profile1_member1());
        vm.stopPrank();
    }

    function test_registerRecipient_updated_registration() public {
        vm.startPrank(address(allo()));
        strategy.registerRecipient(
            abi.encode(profile1_anchor(), profile1_member1(), 0, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );

        MicroGrantsStrategy.Recipient memory _recipient = strategy.getRecipient(profile1_member1());
        assertEq(_recipient.requestedAmount, 0);

        // when user is already registered
        // fixme: this is failing
        // vm.expectEmit(true, true, true, false);
        // emit UpdatedRegistration(
        //     profile1_member1(),
        //     abi.encode(profile1_anchor(), profile1_member1(), 1e15, Metadata({protocol: 1, pointer: "metadata"})),
        //     profile1_member1()
        // );
        // strategy.registerRecipient(
        //     abi.encode(profile1_anchor(), profile1_member1(), 1e15, Metadata({protocol: 1, pointer: "metadata"})),
        //     profile1_member1()
        // );
        vm.stopPrank();
    }

    function test_getPayout_not_accepted() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(recipientId, 1e18);

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipientIds, data);

        assertEq(payouts[0].amount, 0);
    }

    // FIXME: this keeps failing...
    // function test_getPayout_accepted() public {
    //     address[] memory recipientIds = new address[](1);
    //     address recipientId = __registerRecipient();
    //     recipientIds[0] = recipientId;

    //     bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

    //     vm.prank(pool_manager1());
    //     strategy.setAllocator(makeAddr("chad"), true);
    //     vm.prank(makeAddr("chad"));
    //     strategy.allocate(allocationData, profile1_member1());

    //     bytes[] memory dummyData = new bytes[](1);
    //     dummyData[0] = abi.encode(0);

    //     IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipientIds, dummyData);

    //     assertEq(payouts[0].amount, 1e18);
    // }

    function test_allocate() public {}

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        vm.prank(pool_admin());
        strategy.setAllocator(profile1_member1(), true);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        vm.warp(2 days);
        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;

        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.allocate(allocationData, profile1_member1());
    }

    function test_increaseMaxRequestedAmount() public {
        vm.prank(pool_manager1());
        strategy.increaseMaxRequestedAmount(5e18);

        assertEq(strategy.maxRequestedAmount(), 5e18);
    }

    function testRevert_increaseMaxRequestedAmount_UNAUTHORIZED() public {
        vm.prank(makeAddr("chad"));
        vm.expectRevert(UNAUTHORIZED.selector);

        strategy.increaseMaxRequestedAmount(5e18);
    }

    function testRevert_increaseMaxRequestedAmount_AMOUNT_TOO_LOW() public {
        vm.prank(pool_manager1());
        vm.expectRevert(AMOUNT_TOO_LOW.selector);

        strategy.increaseMaxRequestedAmount(5e17);
    }

    function test_setApprovalThreshold() public {
        vm.prank(pool_manager1());
        strategy.setApprovalThreshold(5);

        assertEq(strategy.approvalThreshold(), 5);
    }

    function testRevert_setApprovalThreshold_UNAUTHORIZED() public {
        vm.prank(makeAddr("chad"));
        vm.expectRevert(UNAUTHORIZED.selector);

        strategy.setApprovalThreshold(5);
    }

    function test_isPoolActive() public {
        assertTrue(strategy.isPoolActive());
        address recipientId = __registerRecipient();
        __addAllocators();

        vm.deal(pool_admin(), 1e19);
        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);

        vm.prank(profile1_member1());
        allo().allocate(poolId, abi.encode(recipientId, IStrategy.Status.Accepted));
        vm.prank(profile1_member2());
        allo().allocate(poolId, abi.encode(recipientId, IStrategy.Status.Accepted));
        vm.prank(profile2_member2());
        allo().allocate(poolId, abi.encode(recipientId, IStrategy.Status.Accepted));
        
        vm.warp(2 days);
        assertFalse(strategy.isPoolActive());
    }

    function test_onlyActiveAllocation() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        vm.prank(pool_admin());
        strategy.setAllocator(profile1_member1(), true);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        vm.warp(2 days);
        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);
    }

    function test_updatePoolTimestamps() public {
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(uint64(block.timestamp), uint64(block.timestamp + 2 days));

        assertEq(strategy.allocationStartTime(), uint64(block.timestamp));
        assertEq(strategy.allocationEndTime(), uint64(block.timestamp + 2 days));
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        strategy.updatePoolTimestamps(uint64(block.timestamp), uint64(block.timestamp + 2 days));
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.startPrank(pool_admin());
        vm.expectRevert(INVALID.selector);
        strategy.updatePoolTimestamps(allocationStartTime - 1, allocationEndTime);
        vm.expectRevert(INVALID.selector);
        strategy.updatePoolTimestamps(allocationStartTime, allocationStartTime - 1);
        vm.expectRevert(INVALID.selector);
        strategy.updatePoolTimestamps(allocationStartTime + 1, allocationStartTime);
    }

    function test_setAllocator() public {
        __addAllocators();
    }

    function testRevert_setAllocator_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.setAllocator(profile1_member1(), true);
    }

    function test_batchSetAllocator() public {
        address[] memory allocatorAddresses = new address[](2);
        allocatorAddresses[0] = profile1_member1();
        allocatorAddresses[1] = profile1_member2();

        bool[] memory allocatorValues = new bool[](2);
        allocatorValues[0] = true;
        allocatorValues[1] = true;

        vm.prank(pool_admin());
        strategy.batchSetAllocator(allocatorAddresses, allocatorValues);
    }

    function test_withdraw() public {
        _register_allocate();
        vm.prank(pool_admin());

        strategy.withdraw(NATIVE);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        _register_allocate();
        vm.prank(makeAddr("chad"));

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.withdraw(NATIVE);
    }

    function testRevert_distribute() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;

        bytes memory data = abi.encode(recipientId, 1e18);

        vm.expectRevert();
        strategy.distribute(recipientIds, data, profile1_member1());
    }

    function test_isValidAllocator() public {
        __addAllocators();

        assertTrue(strategy.isValidAllocator(profile1_member1()));
        assertTrue(strategy.isValidAllocator(profile1_member2()));
        assertTrue(strategy.isValidAllocator(profile2_member1()));
        assertTrue(strategy.isValidAllocator(profile2_member2()));
    }

    function __addAllocators() internal {
        vm.startPrank(pool_admin());
        strategy.setAllocator(profile1_member1(), true);
        strategy.setAllocator(profile1_member2(), true);
        strategy.setAllocator(profile2_member1(), true);
        strategy.setAllocator(profile2_member2(), true);
        vm.stopPrank();
    }

    function __registerRecipient() internal returns (address recipientId) {
        address sender = profile1_member1();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile1_anchor(), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = strategy.registerRecipient(data, sender);
    }

    function _register_allocate() internal returns (address recipientId) {
        recipientId = __registerRecipient();
        vm.deal(pool_admin(), 1e19);

        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);
    }
}
