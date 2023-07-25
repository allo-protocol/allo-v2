pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/IAllo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test Helpers
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {Test} from "forge-std/Test.sol";

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

    bool public initialized;

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

        registrationStartTime = block.timestamp;
        registrationEndTime = block.timestamp + 300;
        allocationStartTime = block.timestamp + 301;
        allocationEndTime = block.timestamp + 600;

        registryGating = false;
        metadataRequired = false;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");

        initialized = false;
    }

    function test_initialize() public {
        // vm.expectEmit();
        // emit RoleGranted(
        //     address(strategy), address(strategy), 0xd866368887d58dbdd097c420fb7ec3bf9a28071e2c715e21155ba472632c67b1
        // );
        // emit RoleAdminChanged(
        //     0x0000000000000000000000000000000000000000000000000000000000000001, address(0), address(strategy)
        // );

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

        vm.prank(allo_owner());
        poolId = allo().createPoolWithCustomStrategy(
            alloIdentity_id(),
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

    // Fuzz test the timestamp initialization conditions
    function testFuzz_initialize_timestamps(
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) public {
        vm.assume(_registrationStartTime > block.timestamp);
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationEndTime < _allocationStartTime);
        vm.assume(_allocationStartTime < _allocationEndTime);

        vm.prank(pool_admin());
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                _registrationStartTime,
                _registrationEndTime,
                _allocationStartTime,
                _allocationEndTime
            )
        );
    }

    // Test the timestamp revert conditions
    // Note: the following tests are not exhaustive
    function testRevert_initialize_INVALID_REGISTRATION_START_TIME() public {
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(allo_owner());
        strategy.initialize(
            0,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                500, // Sets a time in the future ahead of the remaining values below
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID_REGISTRATION_END_TIME() public {
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(allo_owner());
        strategy.initialize(
            0,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                700, // Sets a time in the future ahead of the remaining values below,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID_ALLOATION_START_TIME() public {
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(allo_owner());
        strategy.initialize(
            0,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                0, // Sets a time in the past before the registration times
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID_ALLOATION_END_TIME() public {
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(allo_owner());
        strategy.initialize(
            0,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                0 // Sets a time in the past before the registration ends
            )
        );
    }

    function testReviewRecipients() public {
        // address[] memory recipients = new address[](2);
        // QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
        //     new QVSimpleStrategy.InternalRecipientStatus[](2);

        // recipients[0] = recipient1();
        // recipients[1] = recipient2();

        // recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Accepted;
        // recipientStatuses[1] = QVSimpleStrategy.InternalRecipientStatus.Rejected;

        // vm.prank(pool_admin());
        // // add a pool manager for the tests
        // allo().addPoolManager(poolId, pool_manager1());

        // vm.prank(pool_manager1());
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

    function test_getRecipientStatus() public {}

    function test_isValidAllocator() public {}

    function test_setMetadata() public {}

    function testRevert_setMetadata_UNAUTHORIZED() public {}

    function test_setRecipientStatus() public {}

    function test_setRecipientStatus_revert_UNAUTHORIZED() public {}

    function test_getPayouts() public {}

    function test_applyAndRegister() public {}

    function testRevert_applyAndRegister_IDENTITY_REQUIRED() public {}

    function test_allocate() public {
        // uint256 oneDayInSeconds = 86400;
        // uint256 oneWeekInSeconds = oneDayInSeconds * 7;
        // uint256 today = block.timestamp;
        // uint256 yesterday = today - oneDayInSeconds;
        // uint256 lastWeek = today - oneWeekInSeconds;
        // uint256 nextWeek = today + oneWeekInSeconds;
        // uint256 tomorrow = today + oneDayInSeconds;
        // uint256 weekAfterNext = today + 2 * oneWeekInSeconds;

        // registrationStartTime = tomorrow;
        // registrationEndTime = nextWeek;
        // allocationStartTime = nextWeek + oneDayInSeconds;
        // allocationEndTime = weekAfterNext;

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
