pragma solidity ^0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test Helpers
import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";

contract QVSimpleStrategyTest is Accounts, StrategySetup, RegistrySetupFull, AlloSetup, Errors {
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        QVSimpleStrategy.Status recipientStatus;
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

    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    address[] public allowedTokens;
    address public token;

    QVSimpleStrategy public strategy;
    Metadata public poolMetadata;

    event Reviewed(address indexed recipientId, QVBaseStrategy.Status status, address sender);
    event RoleGranted(address indexed recipientId, address indexed account, bytes32 indexed role);
    event RoleAdminChanged(
        bytes32 indexed newAdminRole, address indexed recipientId, address indexed previousAdminRole
    );
    event TimestampsUpdated(
        address indexed recipientId,
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 allocationStartTime,
        uint64 allocationEndTime
    );
    event RecipientStatusUpdated(address indexed recipientId, QVBaseStrategy.Status status, address sender);
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

        poolId = 1337;

        registrationStartTime = uint64(today());
        registrationEndTime = uint64(nextWeek());
        allocationStartTime = uint64(weekAfterNext());
        allocationEndTime = uint64(oneMonthFromNow());

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

        QVSimpleStrategy testStrategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");

        vm.prank(address(allo()));
        testStrategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        1,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }

    // Fuzz test the timestamp initialization conditions
    function testFuzz_initialize_timestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) public {
        vm.assume(_registrationStartTime > block.timestamp);
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationEndTime < _allocationStartTime);
        vm.assume(_allocationStartTime < _allocationEndTime);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                QVSimpleStrategy.InitializeParamsSimple(
                    maxVoiceCreditsPerAllocator,
                    QVBaseStrategy.InitializeParams(
                        registryGating,
                        metadataRequired,
                        1,
                        registrationStartTime,
                        registrationEndTime,
                        allocationStartTime,
                        allocationEndTime
                    )
                )
            )
        );
    }
}
