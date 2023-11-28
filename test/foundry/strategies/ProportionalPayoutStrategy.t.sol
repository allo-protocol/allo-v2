// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategies
import {ProportionalPayoutStrategy} from
    "../../../contracts/strategies/_poc/proportional-payout/ProportionalPayoutStrategy.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test Libraries
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
// Mocks
import {MockERC721} from "../../utils/MockERC721.sol";

contract ProportionalPayoutStrategyTest is Test, Native, Accounts, RegistrySetupFull, AlloSetup, EventSetup, Errors {
    event AllocationTimeSet(uint256 startTime, uint256 endTime);

    /// @notice The maximum number of recipients allowed
    /// @dev This is both to keep the number of choices low and to avoid gas issues
    uint256 constant MAX_RECIPIENTS = 3;

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice When the allocation (voting) period starts
    uint64 public startTime;

    /// @notice When the allocation (voting) period ends
    uint64 public endTime;

    /// @notice The nft required for voting
    MockERC721 public nft;

    /// @notice List of recipients who will receive payout at the end
    address[] public recipients;

    /// @notice Whether or not a recipient is valid
    mapping(address => bool) public isRecipient;

    /// @notice Votes for each recipient
    mapping(address => uint256) public votes;

    /// @notice Whether or not a voter has voted
    /// @dev This is to prevent double voting
    mapping(address => bool) public hasVoted;

    ProportionalPayoutStrategy public strategy;

    Metadata public poolMetadata;

    uint256 public poolId;

    bool public initialized;

    /// @notice Total number of votes cast
    /// @dev This is used to calculate the percentage of votes for each recipient at the end
    uint256 public totalVotes;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        startTime = uint64(block.timestamp + 100);
        endTime = uint64(block.timestamp + 600);
        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        strategy = new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        initialized = false;

        nft = new MockERC721();

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(address(nft), 2, startTime, endTime),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        ProportionalPayoutStrategy testStrategy = __createTestStrategy();
        assertEq(address(testStrategy.getAllo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("ProportionalPayoutStrategy")));
    }

    function test_initialize() public {
        ProportionalPayoutStrategy testStrategy = __createTestStrategy();
        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(nft), 2, startTime, endTime));

        assertEq(testStrategy.getPoolId(), poolId);
        assertEq(testStrategy.allocationStartTime(), startTime);
        assertEq(testStrategy.allocationEndTime(), endTime);
        assertEq(testStrategy.maxRecipientsAllowed(), 2);
        assertTrue(testStrategy.isPoolActive());
        assertEq(address(testStrategy.nft()), address(nft));
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        ProportionalPayoutStrategy testStrategy = __createTestStrategy();
        vm.startPrank(address(allo()));
        testStrategy.initialize(1337, abi.encode(address(nft), 2, startTime, endTime));

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        testStrategy.initialize(1337, abi.encode(address(nft), 2, startTime, endTime));
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        ProportionalPayoutStrategy testStrategy = __createTestStrategy();
        vm.expectRevert(UNAUTHORIZED.selector);

        testStrategy.initialize(1337, abi.encode(address(nft), 2, startTime, endTime));
    }

    function testRevert_initialize_INVALID() public {
        ProportionalPayoutStrategy testStrategy = __createTestStrategy();

        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));

        vm.prank(address(allo()));
        testStrategy.initialize(1337, abi.encode(address(nft), 2, endTime, startTime));
    }

    function test_getRecipient() public {
        address recipientId = __register_recipient();
        ProportionalPayoutStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);

        assertEq(recipient.recipientAddress, recipient1());
    }

    function test_isValidAllocator() public {
        address recipientAddress = recipient1();
        assertFalse(strategy.isValidAllocator(recipientAddress));

        nft.mint(recipientAddress, 1);

        assertTrue(strategy.isValidAllocator(recipientAddress));
    }

    function test_setAllocationTimes() public {
        uint64 _startTime = uint64(block.timestamp + 100);
        uint64 _endTime = uint64(block.timestamp + 600);

        vm.expectEmit(true, false, false, true);
        emit AllocationTimeSet(_startTime, _endTime);

        vm.prank(pool_manager1());
        strategy.setAllocationTime(_startTime, _endTime);

        assertEq(strategy.allocationStartTime(), _startTime);
        assertEq(strategy.allocationEndTime(), _endTime);
    }

    function testRevert_setAllocationTimes_UNAUTHORIZED() public {
        uint64 _startTime = uint64(block.timestamp + 100);
        uint64 _endTime = uint64(block.timestamp + 600);

        vm.expectRevert(abi.encodeWithSelector(UNAUTHORIZED.selector));
        emit AllocationTimeSet(_startTime, _endTime);

        vm.prank(pool_notAManager());
        strategy.setAllocationTime(_startTime, _endTime);
    }

    function testRevert_setAllocationTimes_INVALID() public {
        uint64 _startTime = uint64(block.timestamp - 1);
        uint64 _endTime = uint64(block.timestamp + 600);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_manager1());
        strategy.setAllocationTime(_startTime, _endTime);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_manager1());
        strategy.setAllocationTime(_endTime + 10, _endTime);
    }

    function test_registerRecipient_acceptApplication() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        IStrategy.Status status = strategy.getRecipientStatus(recipient1());
        assertEq(uint8(status), uint8(IStrategy.Status.Accepted));
    }

    function test_registerRecipient_rejectApprovedApplication() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        IStrategy.Status status = strategy.getRecipientStatus(recipient1());
        assertEq(uint8(status), uint8(IStrategy.Status.Accepted));
        assertEq(strategy.recipientsCounter(), 1);

        data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Rejected, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        status = strategy.getRecipientStatus(recipient1());
        assertEq(uint8(status), uint8(IStrategy.Status.Rejected));
        assertEq(strategy.recipientsCounter(), 0);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_zeroRecipientId() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(address(0), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, address(0)));

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_zeroRecipientAddress() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), address(0), IStrategy.Status.Accepted, metadata);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipient1()));

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_invalidStatus() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Pending, metadata);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipient1()));

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);
    }

    function testRevert_registerRecipient_MAX_REACHED() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data =
            abi.encode(makeAddr("recipient1"), makeAddr("recipient1"), IStrategy.Status.Accepted, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        data = abi.encode(makeAddr("recipient2"), makeAddr("recipient2"), IStrategy.Status.Accepted, metadata);
        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        vm.expectRevert(ProportionalPayoutStrategy.MAX_REACHED.selector);
        data = abi.encode(makeAddr("recipient3"), makeAddr("recipient3"), IStrategy.Status.Accepted, metadata);
        vm.prank(pool_manager1());

        allo().registerRecipient(poolId, data);
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.expectRevert(abi.encodeWithSelector(UNAUTHORIZED.selector));

        vm.prank(pool_notAManager());
        allo().registerRecipient(poolId, data);
    }

    function test_getPayouts() public {
        address recipientId = _register_allocate_submit_distribute();
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipientIds, new bytes[](1));
        assertEq(payouts.length, 1);
        assertEq(payouts[0].amount, 9.9e18);
        assertEq(payouts[0].recipientAddress, recipient1());
    }

    function testRevert_getPayouts_mismatch() public {
        address recipientId = _register_allocate_submit_distribute();
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        vm.expectRevert(ARRAY_MISMATCH.selector);

        strategy.getPayouts(recipientIds, new bytes[](0));
    }

    function test_distribute() public {
        address recipientId = _register_allocate_submit_distribute();
        assertTrue(strategy.paidOut(recipientId));
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        address recipientId = _register_allocate_submit_distribute();
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));

        vm.prank(address(allo()));
        strategy.distribute(recipientIds, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_notAcceptedStatus() public {
        address recipientId = makeAddr("notAcceptedStatus");
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        vm.warp(endTime + 10);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));

        vm.prank(address(allo()));
        strategy.distribute(recipientIds, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_amountZero() public {
        address recipientId = __register_recipient();
        // accepted, byt no allocations
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        vm.warp(endTime + 10);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));

        vm.prank(address(allo()));
        strategy.distribute(recipientIds, "", pool_admin());
    }

    function test_allocate() public {
        address recipientId = __register_recipient();

        ProportionalPayoutStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(strategy.totalAllocations(), 0);
        assertFalse(strategy.hasAllocated(1));
        assertEq(recipient.totalVotesReceived, 0);

        nft.mint(makeAddr("nftOwner"), 1);

        vm.warp(startTime + 10);
        vm.prank(makeAddr("nftOwner"));
        vm.expectEmit(true, false, false, true);
        emit Allocated(recipientId, 1, address(0), makeAddr("nftOwner"));

        allo().allocate(poolId, abi.encode(recipientId, 1));

        recipient = strategy.getRecipient(recipientId);

        assertEq(strategy.totalAllocations(), 1);
        assertTrue(strategy.hasAllocated(1));
        assertEq(recipient.totalVotesReceived, 1);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = makeAddr("recipient");
        bytes memory data = abi.encode(recipientId, 1);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        allo().allocate(poolId, data);
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = makeAddr("recipient");
        bytes memory data = abi.encode(recipientId, 1);

        nft.mint(recipient1(), 1);

        vm.warp(startTime + 1);
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(address(allo()));
        allo().allocate(poolId, data);
    }

    function testRevert_allocate_RECIPIENT_ERROR_shit() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.prank(pool_manager1());
        address recipientId = allo().registerRecipient(poolId, data);

        vm.prank(pool_manager1());
        data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Rejected, metadata);
        allo().registerRecipient(poolId, data);

        nft.mint(makeAddr("nftOwner"), 1);
        vm.warp(startTime + 1);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.prank(makeAddr("nftOwner"));
        allo().allocate(poolId, abi.encode(recipientId, 1));
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __register_recipient() internal returns (address recipientId) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "Test Metadata"});
        bytes memory data = abi.encode(recipient1(), recipient1(), IStrategy.Status.Accepted, metadata);

        vm.prank(pool_manager1());
        recipientId = allo().registerRecipient(poolId, data);
    }

    function __register_allocate() internal returns (address recipientId) {
        recipientId = __register_recipient();

        nft.mint(makeAddr("nftOwner"), 1);

        vm.warp(startTime + 1);

        vm.prank(makeAddr("nftOwner"));
        vm.expectEmit(true, false, false, true);
        emit Allocated(recipientId, 1, address(0), makeAddr("nftOwner"));

        allo().allocate(poolId, abi.encode(recipientId, 1));
    }

    function _register_allocate_submit_distribute() internal returns (address recipientId) {
        recipientId = __register_allocate();
        vm.deal(pool_admin(), 1e19);

        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);

        vm.expectEmit(true, false, false, true);
        emit Distributed(recipientId, recipient1(), 9.9e18, pool_admin());

        vm.warp(endTime + 1);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        vm.prank(address(allo()));
        strategy.distribute(recipientIds, "", pool_admin());
    }

    function __createTestStrategy() internal returns (ProportionalPayoutStrategy testStrategy) {
        testStrategy = new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
    }
}
