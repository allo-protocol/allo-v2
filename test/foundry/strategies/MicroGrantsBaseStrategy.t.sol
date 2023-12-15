// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {MicroGrantsStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsStrategy.sol";
import {MicroGrantsBaseStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsBaseStrategy.sol";
import {MockMicroGrantsBaseStrategy} from "../../utils/MockMicroGrantsBaseStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract MicroGrantsBaseStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    event Allocated(address indexed recipientId, IStrategy.Status status, address sender);

    error AMOUNT_TOO_LOW();
    error EXCEEDING_MAX_AMOUNT();

    address payable public _strategy;

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

    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = true;
        allocationStartTime = uint64(block.timestamp);
        allocationEndTime = uint64(block.timestamp + 1 days);
        maxRequestedAmount = 1e18;
        approvalThreshold = 3;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        _strategy = _createStrategy();
        _initialize();
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
        MicroGrantsStrategy.Recipient memory _recipient = mgStrategy().getRecipient(recipientId);

        assertEq(_recipient.useRegistryAnchor, useRegistryAnchor);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Pending));
        assertEq(_recipient.requestedAmount, 1e18);
    }

    function test_getRecipientStatus() public {
        address recipientId = __registerRecipient();
        IStrategy.Status recipientStatus = mgStrategy().getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function test_getRecipient_after_allocation_ended_not_accepted() public {
        address recipientId = __registerRecipient();
        vm.warp(365 days);
        MicroGrantsStrategy.Recipient memory _recipient = mgStrategy().getRecipient(recipientId);

        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Rejected));
    }

    function test_getRecipient_after_allocation_ended_accepted() public {
        address recipientId = __register_allocate_accept();
        vm.warp(365 days);
        MicroGrantsStrategy.Recipient memory _recipient = mgStrategy().getRecipient(recipientId);

        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.prank(address(allo()));
        vm.expectRevert(INVALID_METADATA.selector);

        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e18, Metadata({protocol: 0, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function testRevert_registerRecipient_UNAUTHORIZED_no_registry_member() public {
        vm.prank(address(allo()));
        vm.expectRevert(UNAUTHORIZED.selector);

        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e18, Metadata({protocol: 1, pointer: "metadata"})),
            randomAddress()
        );
    }

    function testRevert_registerRecipient_UNAUTHORIZED_already_allocated() public {
        __register_allocate_accept();
        vm.prank(address(allo()));
        vm.expectRevert(UNAUTHORIZED.selector);

        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e18, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_zero_recipientAddress() public {
        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), address(0), 1e18, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function testRevert_registerRecipient_EXCEEDING_MAX_AMOUNT() public {
        vm.prank(address(allo()));
        vm.expectRevert(EXCEEDING_MAX_AMOUNT.selector);

        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), recipientAddress(), 1e19, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );
    }

    function test_registerRecipient_ZERO_AMOUNT() public {
        bytes memory registrationData =
            abi.encode(profile1_anchor(), profile1_member1(), 0, Metadata({protocol: 1, pointer: "metadata"}));

        vm.startPrank(address(allo()));
        address recipientId = mgStrategy().registerRecipient(registrationData, profile1_member1());
        vm.stopPrank();

        MicroGrantsStrategy.Recipient memory _recipient = mgStrategy().getRecipient(recipientId);
        assertEq(_recipient.requestedAmount, 1e18);
    }

    function test_registerRecipient_updated_registration() public {
        vm.startPrank(address(allo()));

        bytes memory registrationData =
            abi.encode(profile1_anchor(), profile1_member1(), 0, Metadata({protocol: 1, pointer: "metadata"}));

        address recipientId = mgStrategy().registerRecipient(registrationData, profile1_member1());

        vm.expectEmit(true, true, true, false);
        emit UpdatedRegistration(
            recipientId,
            abi.encode(profile1_anchor(), profile1_member1(), 1, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );
        mgStrategy().registerRecipient(
            abi.encode(profile1_anchor(), profile1_member1(), 1, Metadata({protocol: 1, pointer: "metadata"})),
            profile1_member1()
        );

        vm.stopPrank();
    }

    function test_getPayout_not_accepted() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(recipientId, 1e18);

        IStrategy.PayoutSummary[] memory payouts = mgStrategy().getPayouts(recipientIds, data);

        assertEq(payouts[0].amount, 1e18);
    }

    function test_getPayout_accepted() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __register_allocate_accept();
        recipientIds[0] = recipientId;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(0);

        IStrategy.PayoutSummary[] memory payouts = mgStrategy().getPayouts(recipientIds, data);

        assertEq(payouts[0].amount, 0);
    }

    function test_allocate_accepted() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        __setAllocator(profile1_member1(), true);

        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);

        assertTrue(mgStrategy().allocated(profile1_member1(), recipientId));
        assertEq(mgStrategy().recipientAllocations(recipientId, IStrategy.Status.Accepted), 1);
    }

    function test_allocate_rejected() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Rejected);

        __setAllocator(profile1_member1(), true);

        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);

        assertTrue(mgStrategy().allocated(profile1_member1(), recipientId));
        assertEq(mgStrategy().recipientAllocations(recipientId, IStrategy.Status.Rejected), 1);
    }

    function test_allocate_and_distribute() public {
        uint256 recipientBalanceBefore = address(recipientAddress()).balance;
        address recipientId = __register_allocate_accept();

        uint256 recipientBalanceAfter = address(recipientAddress()).balance;
        assertEq(recipientBalanceAfter - recipientBalanceBefore, 1e18);
        assertEq(uint8(mgStrategy().getRecipient(recipientId).recipientStatus), uint8(IStrategy.Status.Accepted));
    }

    function testRevert_allocate_RECIPIENT_ERROR_alreadyAllocated() public {
        address recipientId = __register_allocate_accept();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);
    }

    function testRevert_allocate_RECIPIENT_ERROR_statusAccepted() public {
        address recipientId = __register_allocate_accept();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        __setAllocator(makeAddr("newAllocator"), true);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.prank(makeAddr("newAllocator"));
        allo().allocate(poolId, allocationData);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        __setAllocator(profile1_member1(), true);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        vm.warp(2 days);
        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);
    }

    function testRevert_allocate_UNAUTHORIZED() public virtual {}

    function test_increaseMaxRequestedAmount() public {
        vm.prank(pool_manager1());
        mgStrategy().increaseMaxRequestedAmount(5e18);

        assertEq(mgStrategy().maxRequestedAmount(), 5e18);
    }

    function testRevert_increaseMaxRequestedAmount_UNAUTHORIZED() public {
        vm.prank(makeAddr("chad"));
        vm.expectRevert(UNAUTHORIZED.selector);

        mgStrategy().increaseMaxRequestedAmount(5e18);
    }

    function testRevert_increaseMaxRequestedAmount_AMOUNT_TOO_LOW() public {
        vm.prank(pool_manager1());
        vm.expectRevert(AMOUNT_TOO_LOW.selector);

        mgStrategy().increaseMaxRequestedAmount(5e17);
    }

    function test_setApprovalThreshold() public {
        vm.prank(pool_manager1());
        mgStrategy().setApprovalThreshold(5);

        assertEq(mgStrategy().approvalThreshold(), 5);
    }

    function testRevert_setApprovalThreshold_UNAUTHORIZED() public {
        vm.prank(makeAddr("chad"));
        vm.expectRevert(UNAUTHORIZED.selector);

        mgStrategy().setApprovalThreshold(5);
    }

    function test_isPoolActive() public {
        assertTrue(mgStrategy().isPoolActive());
        vm.warp(2 days);
        assertFalse(mgStrategy().isPoolActive());
    }

    function test_onlyActiveAllocation() public {
        address recipientId = __registerRecipient();
        // decoded data => (address recipientId, Status status)
        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        __setAllocator(profile1_member1(), true);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        vm.warp(2 days);
        vm.prank(profile1_member1());
        allo().allocate(poolId, allocationData);
    }

    function test_updatePoolTimestamps() public {
        vm.prank(pool_admin());
        mgStrategy().updatePoolTimestamps(uint64(block.timestamp), uint64(block.timestamp + 2 days));

        assertEq(mgStrategy().allocationStartTime(), uint64(block.timestamp));
        assertEq(mgStrategy().allocationEndTime(), uint64(block.timestamp + 2 days));
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        mgStrategy().updatePoolTimestamps(uint64(block.timestamp), uint64(block.timestamp + 2 days));
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.startPrank(pool_admin());
        vm.expectRevert(INVALID.selector);
        mgStrategy().updatePoolTimestamps(allocationStartTime - 1, allocationEndTime);
        vm.expectRevert(INVALID.selector);
        mgStrategy().updatePoolTimestamps(allocationStartTime, allocationStartTime - 1);
        vm.expectRevert(INVALID.selector);
        mgStrategy().updatePoolTimestamps(allocationStartTime + 1, allocationStartTime);
        vm.stopPrank();
    }

    function test_withdraw() public {
        _register_fundPool();
        vm.prank(pool_admin());

        mgStrategy().withdraw(NATIVE);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        _register_fundPool();
        vm.prank(makeAddr("chad"));

        vm.expectRevert(UNAUTHORIZED.selector);
        mgStrategy().withdraw(NATIVE);
    }

    function testRevert_distribute() public {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;

        bytes memory data = abi.encode(recipientId, 1e18);

        vm.expectRevert();
        mgStrategy().distribute(recipientIds, data, profile1_member1());
    }

    function test_isValidAllocator() public {
        __addAllocators();

        assertTrue(mgStrategy().isValidAllocator(profile1_member1()));
        assertTrue(mgStrategy().isValidAllocator(profile1_member2()));
        assertTrue(mgStrategy().isValidAllocator(profile2_member1()));
        assertTrue(mgStrategy().isValidAllocator(profile2_member2()));
    }

    function __addAllocators() internal virtual {}

    function __registerRecipient() internal returns (address recipientId) {
        address sender = profile1_member1();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(profile1_anchor(), recipientAddress(), 1e18, metadata);
        vm.prank(address(allo()));
        recipientId = mgStrategy().registerRecipient(data, sender);
    }

    function _register_fundPool() internal returns (address recipientId) {
        recipientId = __registerRecipient();
        vm.deal(pool_admin(), 1e19);

        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);
    }

    function __register_allocate_accept() internal returns (address) {
        address recipientId = __registerRecipient();

        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        address[] memory _allocators = new address[](3);
        _allocators[0] = profile1_member1();
        _allocators[1] = profile1_member2();
        _allocators[2] = profile2_member1();

        bool[] memory allocatorValues = new bool[](3);
        allocatorValues[0] = true;
        allocatorValues[1] = true;
        allocatorValues[2] = true;

        vm.deal(pool_admin(), 1e19);
        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);

        __addAllocators();

        uint256 poolAmountBefore = mgStrategy().getPoolAmount();

        for (uint256 i = 0; i < _allocators.length - 1; i++) {
            vm.prank(address(allo()));
            mgStrategy().allocate(allocationData, _allocators[i]);
            assertEq(mgStrategy().recipientAllocations(recipientId, IStrategy.Status.Accepted), i + 1);
        }

        vm.prank(address(allo()));
        vm.expectEmit(true, true, true, true);

        emit Distributed(recipientId, recipientAddress(), 1e18, _allocators[2]);
        mgStrategy().allocate(allocationData, _allocators[2]);

        assertEq(mgStrategy().recipientAllocations(recipientId, IStrategy.Status.Accepted), 3);

        uint256 poolAmountAfter = mgStrategy().getPoolAmount();

        assertEq(poolAmountBefore - poolAmountAfter, 1e18);

        return recipientId;
    }

    function __setAllocator(address allocator, bool value) internal virtual {}

    function _createStrategy() internal virtual returns (address payable) {
        return payable(address(new MockMicroGrantsBaseStrategy(address(allo()), "MicroGrantsStrategy")));
    }

    function _initialize() internal virtual {
        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();
        vm.stopPrank();
    }

    function _createPoolWithCustomStrategy() internal virtual {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function mgStrategy() internal view returns (MicroGrantsBaseStrategy) {
        return (MicroGrantsBaseStrategy(payable(address(_strategy))));
    }
}
