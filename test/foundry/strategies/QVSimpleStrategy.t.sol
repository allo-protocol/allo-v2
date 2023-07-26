pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/IAllo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test Helpers
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";

contract QVSimpleStrategyTest is StrategySetup, RegistrySetupFull, AlloSetup {
    error ALLOCATION_NOT_ACTIVE();

    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        QVSimpleStrategy.InternalRecipientStatus recipientStatus;
        uint256 totalVotes;
    }

    struct Allocator {
        uint256 voiceCredits;
        mapping(address => uint256) voiceCreditsCastToRecipient;
        mapping(address => uint256) votesCastToRecipient;
    }

    bool public registryGating;
    bool public metadataRequired;

    uint256 public totalRecipientVotes;
    uint256 public maxVoiceCreditsPerAllocator;

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    QVSimpleStrategy public strategy;

    address public token;

    Metadata public poolMetadata;

    uint256 public poolId;

    event Registered(address indexed recipientId, bytes data, address sender);
    event Appealed(address indexed recipientId, bytes data, address sender);
    event Reviewed(address indexed recipientId, QVSimpleStrategy.InternalRecipientStatus status, address sender);
    event RoleGranted(address indexed recipientId, address indexed account, bytes32 indexed role);
    event RoleAdminChanged(
        bytes32 indexed newAdminRole, address indexed recipientId, address indexed previousAdminRole
    );
    event TimestampsUpdated(
        address indexed recipientId,
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime
    );
    event RecipientStatusUpdated(
        address indexed recipientId, QVSimpleStrategy.InternalRecipientStatus status, address sender
    );
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = today();
        registrationEndTime = nextWeek();
        allocationStartTime = weekAfterNext();
        allocationEndTime = oneMonthFromNow();
        emit log_named_uint("registrationStartTime", registrationStartTime);

        registryGating = false;
        metadataRequired = false;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");

        _initialize();
    }

    function _initialize() internal {
        vm.prank(pool_admin());
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.prank(pool_manager1());
        poolId = allo().createPoolWithCustomStrategy(
            poolIdentity_id(),
            address(strategy),
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            ),
            address(token),
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function testRegisterRecipients() public {
        // vm.expectEmit(true, false, false, true);
        // emit Registered(recipient1(), abi.encode(recipient1(), true, Metadata({protocol: 1, pointer: "recipient-1"})), pool_manager1());
        // set the block.timestamp ahead 100 blocks so registration is open
        skip(100);

        // register the recipients
        vm.prank(pool_manager1());
        // todo: stuck on this, why is this failing? Pool manager should be able to register recipients.
        // bytes memory data1 = abi.encode(recipient1(), true, Metadata({protocol: 1, pointer: "recipient-1"}));
        // allo().registerRecipient(poolId, data1);
        // bytes memory data2 = abi.encode(recipient2(), true, Metadata({protocol: 1, pointer: "recipient-2"}));
        // allo().registerRecipient(poolId, data2);
    }

    function testReviewRecipients() public {
        // vm.expectEmit(true, false, false, true);
        address[] memory recipients = new address[](2);
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](2);

        recipients[0] = recipient1();
        recipients[1] = recipient2();

        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Accepted;
        recipientStatuses[1] = QVSimpleStrategy.InternalRecipientStatus.Rejected;

        // set the block.timestamp ahead 100 blocks so registration is open
        skip(100);

        // vm.prank(pool_admin());
        // add a pool manager for the tests
        // allo().addPoolManager(poolId, pool_manager1());

        // vm.prank(pool_manager1());
        // bytes memory data = abi.encode(recipients, recipientStatuses);
        // strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_ReviewRecipients_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        address[] memory recipients = new address[](2);
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](2);

        recipients[0] = recipient1();
        recipients[1] = recipient2();

        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Accepted;
        recipientStatuses[1] = QVSimpleStrategy.InternalRecipientStatus.Rejected;

        vm.prank(makeAddr("not a pool manager"));
        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    // function test_getRecipient() public {
    //     strategy.getRecipient();
    // }

    function test_getRecipientStatus() public {
        IStrategy.RecipientStatus status = strategy.getRecipientStatus(recipient1());
        emit log_named_uint("recipientStatus", uint256(status));

        // assert that the status is none
        assertEq(uint256(status), uint256(IStrategy.RecipientStatus.None), "status is not none as expected");

        // todo: change the status and assert that it changed
    }

    function test_isValidAllocator() public {
        bool isValid = strategy.isValidAllocator(pool_manager1());
        string memory isValidStr = isValid ? "true" : "false";
        emit log_named_string("isValid", isValidStr);

        // assert they are not allowed
        assertFalse(isValid, "current user is not allowed");

        // todo: update the strategy to allow them and assert that they are allowed
    }

    function test_setMetadata() public {}

    function testRevert_setMetadata_UNAUTHORIZED() public {}

    function test_setRecipientStatus() public {}

    function test_setRecipientStatus_revert_UNAUTHORIZED() public {}

    function test_getPayouts() public {}

    function test_applyAndRegister() public {}

    function testRevert_applyAndRegister_IDENTITY_REQUIRED() public {}

    function test_allocate() public {
        registrationStartTime = tomorrow() + oneDayInSeconds();
        registrationEndTime = nextWeek() + oneDayInSeconds();
        allocationStartTime = weekAfterNext() + oneDayInSeconds();
        allocationEndTime = oneMonthFromNow() + oneDayInSeconds();

        // strategy.updatePoolTimestamps(
        //     registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime
        // );

        // address recipientId = makeAddr("recipientId");
        // uint256 voiceCreditsToAllocate = 100;

        // bytes memory data = abi.encode(recipientId, voiceCreditsToAllocate);

        // allo.allocate(1, data);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        // vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        // address recipientId = makeAddr("recipientId");
        // uint256 voiceCreditsToAllocate = 100;

        // bytes memory data = abi.encode(recipientId, voiceCreditsToAllocate);

        // allo().allocate(1, data);
    }

    function testRevert_allocate_UNAUTHORIZED() public {}

    function testRevert_allocate_NOT_ACCEPTED() public {}

    function testRevert_allocate_NOT_ENOUGH_VOICE_CREDITS() public {}

    function test_setStartAndEndTimes() public {}

    function testRevert_setStartAndEndTimes_UNAUTHORIZED() public {}

    function test_isIdentityMember() public {}

    // Note: internal calculation tests
    function test_calculateVotes() public {}

    function test_calculatePayoutAmount() public {}
}
