pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {BaseStrategy} from "../../../../contracts/strategies/BaseStrategy.sol";
import {QVSimpleStrategy} from "../../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {Allo} from "../../../../contracts/core/Allo.sol";
import {Registry} from "../../../../contracts/core/Registry.sol";

contract QVSimpleStrategyTest is Test {
    error ALLOCATION_NOT_ACTIVE();

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        InternalRecipientStatus recipientStatus;
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

    Allo public allo;
    Registry public registry;
    QVSimpleStrategy public strategy;

    address public alloOwner;
    address public owner;
    address public member1;
    address public member2;
    address[] public members;
    address payable public treasury;

    address public token;

    Metadata public metadata;
    string public name;
    uint256 public nonce;
    uint256 public poolId;

    bytes32 public identityId;
    bool public initialized;

    event Appealed(address indexed recipientId, bytes data, address sender);
    event Reviewed(address indexed recipientId, InternalRecipientStatus status, address sender);

    function setUp() public {
        registrationStartTime = block.timestamp;
        registrationEndTime = block.timestamp + 300;
        allocationStartTime = block.timestamp + 301;
        allocationEndTime = block.timestamp + 600;

        registryGating = false;
        metadataRequired = false;

        alloOwner = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        owner = makeAddr("owner");

        allo = new Allo();

        member1 = makeAddr("member1");
        member2 = makeAddr("member2");

        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        nonce = 2;

        registry = new Registry(owner);
        treasury = payable(makeAddr("treasury"));
        allo.initialize(address(registry), treasury, 1e16, 0, 0);

        members = new address[](3);
        members[0] = member1;
        members[1] = member2;

        members[2] = owner;

        allo.updateTreasury(treasury);

        // todo: setup strategy
        strategy = new QVSimpleStrategy(address(allo), "QVSimpleStrategy");

        identityId = registry.createIdentity(nonce, name, metadata, owner, members);
        initialized = false;

        vm.prank(owner);
        poolId = allo.createPoolWithCustomStrategy(
            identityId,
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
            address(0),
            0,
            metadata,
            members
        );
    }

    function test_initialize() public {}

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {}

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
        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        address recipientId = makeAddr("recipientId");
        uint256 voiceCreditsToAllocate = 100;

        bytes memory data = abi.encode(recipientId, voiceCreditsToAllocate);

        allo.allocate(1, data);
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

    // Note: to run the following function tests make the function(s) are/is public in QVSimpleStrategy.sol
    // function test_sqrt() public {
    //     assertEq(strategy._sqrt(4), 2);
    //     assertEq(strategy._sqrt(9), 3);
    //     assertEq(strategy._sqrt(16), 4);
    // }

    // function test_sqrtWei() public {
    //     assertEq(strategy._sqrtWei(400000000000000000), 632455532);
    //     assertEq(strategy._sqrtWei(900000000000000000), 948683298);
    //     assertEq(strategy._sqrtWei(1600000000000000000), 1264911064);
    // }
}
