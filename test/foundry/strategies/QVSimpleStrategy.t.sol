pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/IAllo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";

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
    bool public useRegistryAnchor;

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
        metadataRequired = true;
        maxVoiceCreditsPerAllocator = 100;
        useRegistryAnchor = false;

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
        _createPoolWithCustomStrategy();
    }

    function _createPoolWithCustomStrategy() internal {
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

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("QVSimpleStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
    }

    function test_initialize_BaseStrategy_UNAUTHORIZED() public {
        // vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        // todo: this should revert and is not...
        // vm.prank(makeAddr("random chad"));
        // strategy.initialize(
        //     poolId,
        //     abi.encode(
        //         registryGating,
        //         metadataRequired,
        //         maxVoiceCreditsPerAllocator,
        //         registrationStartTime,
        //         registrationEndTime,
        //         allocationStartTime,
        //         allocationEndTime
        //     )
        // );
    }

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
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
    }

    function test_registerRecipient_new() public {
        vm.warp(registrationStartTime + 10);
        address sender = recipient1();
        address recipientAddress = makeAddr("recipientAddress");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        QVSimpleStrategy.Recipient memory receipt = strategy.getRecipient(recipientId);

        assertEq(receipt.useRegistryAnchor, useRegistryAnchor);
        assertEq(receipt.recipientAddress, recipientAddress);
        assertEq(receipt.metadata.pointer, metadata.pointer);
        assertEq(receipt.metadata.protocol, metadata.protocol);
        assertEq(uint8(receipt.recipientStatus), uint8(QVSimpleStrategy.InternalRecipientStatus.Pending));
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.warp(registrationStartTime + 10);
        bytes memory data = _generateRecipientWithId(poolIdentity_anchor());

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, pool_admin());

        QVSimpleStrategy.Recipient memory receipt = strategy.getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);
    }

    function test_registerRecipient_appeal() public {}

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        bytes memory data = _generateRecipientWithoutId("recipient", false);
        strategy.registerRecipient(data, msg.sender);
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(QVSimpleStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = _generateRecipientWithoutId("recipient", false);
        strategy.registerRecipient(data, recipient1());
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(QVSimpleStrategy.UNAUTHORIZED.selector);

        bytes memory data = abi.encode(recipientAddress, true, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(QVSimpleStrategy.UNAUTHORIZED.selector);

        address sender = recipient1();
        bytes memory data = _generateRecipientWithId(sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(abi.encodeWithSelector(QVSimpleStrategy.RECIPIENT_ERROR.selector, sender));

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(QVSimpleStrategy.INVALID_METADATA.selector);
        address recipientAddress = recipient2();
        Metadata memory metadata = Metadata({protocol: 1, pointer: ""});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(QVSimpleStrategy.INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
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
        vm.warp(registrationStartTime + 10);

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

        vm.prank(pool_notAManager());
        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_INVALID() public {}

    function testRevert_reviewRecipients_RECIPIENT_ERROR() public {}

    // function test_getRecipient() public {
    //     strategy.getRecipient();
    // }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = strategy.registerRecipient(_generateRecipientWithoutId("recipient", false), sender);

        BaseStrategy.RecipientStatus receiptStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(receiptStatus));
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

    function test_setPayout() public {}

    function testRevert_setPayout() public {}

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

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    // Note: internal calculation tests
    function test_calculateVotes() public {}

    function test_calculatePayoutAmount() public {}

    function _generateRecipientWithoutId(string memory _recipientId, bool _isUsingRegistryAnchor)
        internal
        returns (bytes memory)
    {
        address recipientAddress = makeAddr(string(abi.encodePacked("recipientAddress", _recipientId)));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(recipientAddress, _isUsingRegistryAnchor, metadata);
    }

    function _generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        address recipientAddress = makeAddr(string(abi.encodePacked("recipientAddress", _recipientId)));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress, metadata);
    }
}
