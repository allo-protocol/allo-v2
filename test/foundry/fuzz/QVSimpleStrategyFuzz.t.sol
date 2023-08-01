pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/IAllo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test Helpers
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";

contract QVSimpleStrategyTest is Accounts, StrategySetup, RegistrySetupFull, AlloSetup {
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
    bool public initialized;

    uint256 public totalRecipientVotes;
    uint256 public maxVoiceCreditsPerAllocator;
    uint256 public poolId;

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    address[] public allowedTokens;
    address public token;

    QVSimpleStrategy public strategy;
    Metadata public poolMetadata;

    event Appealed(address indexed recipientId, bytes data, address sender);
    event Reviewed(address indexed recipientId, QVBaseStrategy.InternalRecipientStatus status, address sender);
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
        address indexed recipientId, QVBaseStrategy.InternalRecipientStatus status, address sender
    );
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
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

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                1,
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
                1,
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

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                1,
                maxVoiceCreditsPerAllocator,
                _registrationStartTime,
                _registrationEndTime,
                _allocationStartTime,
                _allocationEndTime
            )
        );
    }

    // FIXME: Fuzz test the timestamp update conditions
    // function testFuzz_updatePoolTimestamps(
    //     uint256 _registrationStartTime,
    //     uint256 _registrationEndTime,
    //     uint256 _allocationStartTime,
    //     uint256 _allocationEndTime
    // ) public {
    //     vm.assume(_registrationStartTime > block.timestamp);
    //     vm.assume(_registrationStartTime < _registrationEndTime);
    //     vm.assume(_registrationEndTime < _allocationStartTime);
    //     vm.assume(_allocationStartTime < _allocationEndTime && _allocationStartTime < _allocationEndTime);

    //     vm.prank(address(allo()));
    //     strategy.initialize(
    //         poolId,
    //         abi.encode(
    //             registryGating,
    //             metadataRequired,
    //             maxVoiceCreditsPerAllocator,
    //             _registrationStartTime,
    //             _registrationEndTime,
    //             _allocationStartTime,
    //             _allocationEndTime
    //         )
    //     );

    //     vm.startPrank(pool_manager1());
    //     poolId = allo().createPoolWithCustomStrategy(
    //         poolIdentity_id(),
    //         address(strategy),
    //         abi.encode(
    //             registryGating,
    //             metadataRequired,
    //             maxVoiceCreditsPerAllocator,
    //             registrationStartTime,
    //             registrationEndTime,
    //             allocationStartTime,
    //             allocationEndTime
    //         ),
    //         address(token),
    //         0,
    //         poolMetadata,
    //         pool_managers()
    //     );

    //     vm.warp(1000);

    //     strategy.updatePoolTimestamps(
    //         _registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime
    //     );
    // }
}
