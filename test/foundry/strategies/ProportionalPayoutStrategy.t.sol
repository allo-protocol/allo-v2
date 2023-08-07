// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Strategies
import {ProportionalPayoutStrategy} from
    "../../../contracts/strategies/proportional-payout/ProportionalPayoutStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// Test Libraries
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
// Mocks
import {MockNFT} from "../../utils/MockNFT.sol";

contract ProportionalPayoutStrategyTest is Test, Accounts, RegistrySetupFull, AlloSetup, EventSetup {
    error RECIPIENT_ERROR(address recipientId);
    error MAX_REACHED();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error INVALID();

    event AllocationTimeSet(uint256 startTime, uint256 endTime);

    /// @notice The maximum number of recipients allowed
    /// @dev This is both to keep the number of choices low and to avoid gas issues
    uint256 constant MAX_RECIPIENTS = 3;

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice When the allocation (voting) period starts
    uint256 public startTime;

    /// @notice When the allocation (voting) period ends
    uint256 public endTime;

    /// @notice The nft required for voting
    MockNFT public nft;

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

        startTime = block.timestamp + 100;
        endTime = block.timestamp + 600;
        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        strategy = new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        initialized = false;

        nft = MockNFT(makeAddr("nft"));

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(address(nft), 20, startTime, endTime),
            address(0),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        ProportionalPayoutStrategy testStrategy =
            new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        assertEq(address(allo()), address(allo()));
        assertEq(testStrategy.getStrategyId(), keccak256(abi.encode("ProportionalPayoutStrategy")));
    }

    function test_initialize() public {
        ProportionalPayoutStrategy testStrategy =
            new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        vm.prank(address(allo()));
        testStrategy.initialize(poolId, abi.encode(address(nft), 20, startTime, endTime));

        assertEq(testStrategy.allocationStartTime(), startTime);
        assertEq(testStrategy.allocationEndTime(), endTime);
        assertEq(testStrategy.maxRecipientsAllowed(), 20);
        assertTrue(testStrategy.isPoolActive());
        assertEq(address(testStrategy.nft()), address(nft));
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        ProportionalPayoutStrategy testStrategy =
            new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        vm.startPrank(address(allo()));
        testStrategy.initialize(1337, abi.encode(address(nft), 20, startTime, endTime));

        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);
        testStrategy.initialize(1337, abi.encode(address(nft), 20, startTime, endTime));
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        ProportionalPayoutStrategy testStrategy =
            new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        testStrategy.initialize(1337, abi.encode(address(nft), 20, startTime, endTime));
    }

    function testRevert_initialize_INVALID() public {
        ProportionalPayoutStrategy testStrategy =
            new ProportionalPayoutStrategy(address(allo()), "ProportionalPayoutStrategy");

        vm.expectRevert(abi.encodeWithSelector(ProportionalPayoutStrategy.INVALID.selector));

        vm.prank(address(allo()));
        testStrategy.initialize(1337, abi.encode(address(nft), 20, endTime, startTime));
    }

    function test_getRecipient() public {
        address recipientId = __register_recipient();
        ProportionalPayoutStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);

        assertEq(recipient.recipientAddress, recipient1());
    }

    function test_isValidAllocator() public {
        // address recipientAddress = recipient1();
        // todo: this keeps failing on mint...
        // nft.mint(recipientAddress);

        // emit log_named_uint("balance", nft.balanceOf(recipientAddress));

        // assertTrue(strategy.isValidAllocator(recipientAddress));
    }

    function test_registerRecipient() public {
        address recipientAddress = recipient1();
        vm.deal(recipientAddress, 1000000000000000000);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "I am Chad"});
        bytes memory data = abi.encode(recipientAddress, recipientAddress, IStrategy.RecipientStatus.Accepted, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        IStrategy.RecipientStatus status = strategy.getRecipientStatus(recipientAddress);
        assertEq(uint8(status), uint8(IStrategy.RecipientStatus.Accepted));
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        address recipientAddress = nullProfile_member1();
        vm.deal(recipientAddress, 1000000000000000000);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "I am Chad"});
        bytes memory data = abi.encode(recipientAddress, recipientAddress, IStrategy.RecipientStatus.Accepted, metadata);

        vm.expectRevert(abi.encodeWithSelector(ProportionalPayoutStrategy.RECIPIENT_ERROR.selector, recipientAddress));

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        address recipientAddress = nullProfile_member1();
        vm.deal(recipientAddress, 1000000000000000000);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "I am Chad"});
        bytes memory data = abi.encode(recipientAddress, recipientAddress, IStrategy.RecipientStatus.Accepted, metadata);

        vm.expectRevert(abi.encodeWithSelector(IStrategy.BaseStrategy_UNAUTHORIZED.selector));

        vm.prank(pool_notAManager());
        allo().registerRecipient(poolId, data);
    }

    function test_getPayouts() public {
        _register_allocate_submit_distribute();
        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, new bytes[](0));
        assertEq(payouts.length, 1);
        assertEq(payouts[0].amount, 1e18);
        assertEq(payouts[0].recipientAddress, recipient1());
    }

    function test_allocate() public {}

    function testRevert_allocate_UNAUTHORIZED() public {
        // address recipientId = makeAddr("recipient");
        // bytes memory data = abi.encode(recipientId, 1);

        // vm.expectRevert(abi.encodeWithSelector(ProportionalPayoutStrategy.UNAUTHORIZED.selector));

        // // TODO:
        // vm.prank(address(allo()));
        // allo().allocate(poolId, data);
    }

    // TODO:
    function testRevert_allocate_RECIPIENT_ERROR() public {
        // vm.expectRevert(NotElligibleVoter.selector);
        // address recipientId = makeAddr("recipient");
        // bytes memory data = abi.encode(recipientId, amount);

        // allo().allocate(poolId, data);
    }

    function test_setAllocationTimes() public {
        uint256 _startTime = block.timestamp + 100;
        uint256 _endTime = block.timestamp + 600;

        vm.expectEmit(true, false, false, true);
        emit AllocationTimeSet(_startTime, _endTime);

        vm.prank(pool_manager1());
        strategy.setAllocationTime(_startTime, _endTime);

        assertEq(strategy.allocationStartTime(), _startTime);
        assertEq(strategy.allocationEndTime(), _endTime);
    }

    function testRevert_setAllocationTimes_UNAUTHORIZED() public {
        uint256 _startTime = block.timestamp + 100;
        uint256 _endTime = block.timestamp + 600;

        vm.expectRevert(abi.encodeWithSelector(IStrategy.BaseStrategy_UNAUTHORIZED.selector));
        emit AllocationTimeSet(_startTime, _endTime);

        vm.prank(pool_notAManager());
        strategy.setAllocationTime(_startTime, _endTime);
    }

    function __register_recipient() internal returns (address recipientId) {
        address recipientAddress = recipient1();
        vm.deal(recipientAddress, 1000000000000000000);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "I am Chad"});
        bytes memory data = abi.encode(recipientAddress, recipientAddress, IStrategy.RecipientStatus.Accepted, metadata);

        vm.prank(pool_manager1());
        recipientId = allo().registerRecipient(poolId, data);
    }

    function _register_allocate_submit_distribute() internal returns (address recipientId) {
        recipientId = __register_recipient();
        vm.deal(pool_admin(), 1e19);

        vm.prank(pool_admin());
        allo().fundPool{value: 1e19}(poolId, 1e19);

        vm.expectEmit(true, false, false, true);
        emit Distributed(recipientId, recipientAddress(), 7e17, pool_admin());

        vm.prank(address(allo()));
        strategy.distribute(new address[](0), "", pool_admin());
    }
}
