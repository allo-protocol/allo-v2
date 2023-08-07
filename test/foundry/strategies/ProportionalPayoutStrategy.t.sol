pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ProportionalPayoutStrategy} from
    "../../../contracts/strategies/proportional-payout/ProportionalPayoutStrategy.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test Libraries
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

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
    IERC721 public nft;

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

        nft = IERC721(makeAddr("nft"));

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(nft, 20, startTime, endTime),
            address(0),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_initialize() public {}

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {}

    function test_getRecipient() public {
        address recipientId = __register_recipient();
        ProportionalPayoutStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);

        assertEq(recipient.recipientAddress, recipient1());
    }

    function test_getRecipientStatus() public {}

    function test_isValidAllocator() public {
        address recipientId = makeAddr("recipient");
        vm.deal(recipientId, 1000000000000000000);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "I am Chad"});
        bytes memory data = abi.encode(recipientId, recipientId, IStrategy.RecipientStatus.Accepted, metadata);

        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);

        // assertTrue(strategy.isValidAllocator(recipientId));
    }

    function test_registerRecipient() public {
        address recipientAddress = recipient();
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

    function test_getPayouts() public {}

    function test_applyAndRegister() public {}

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
}
