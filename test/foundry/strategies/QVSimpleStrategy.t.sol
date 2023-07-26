pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../../contracts/core/IAllo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test Helpers
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";

// Mocks
import {MockToken} from "../../utils/MockToken.sol";

contract QVSimpleStrategyTest is StrategySetup, RegistrySetupFull, AlloSetup, Native {
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

    MockToken public token;

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
        MockToken token,
        uint256 amount,
        Metadata metadata
    );

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        token = new MockToken();

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

        vm.prank(pool_admin());
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
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
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

    // FIXME
    function test_initialize_BaseStrategy_UNAUTHORIZED() public {
        vm.prank(allo_owner());
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
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

    function testRevert_initialize_INVALID() public {
        strategy = new QVSimpleStrategy(address(allo()), "QVSimpleStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                today() - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when registrationStartTime > registrationEndTime
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                weekAfterNext(),
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                oneMonthFromNow() + today(),
                allocationEndTime
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                oneMonthFromNow() + today(),
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
        bytes memory data = __generateRecipientWithId(poolIdentity_anchor());

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, pool_admin());

        QVSimpleStrategy.Recipient memory receipt = strategy.getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);
    }

    function test_registerRecipient_appeal() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        // appeal
        bytes memory data = __generateRecipientWithoutId(false);
        vm.expectEmit(true, false, false, true);
        emit Appealed(recipientId, data, sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function test_getInternalRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(false), sender);

        QVSimpleStrategy.InternalRecipientStatus recipientStatus = strategy.getInternalRecipientStatus(recipientId);
        assertEq(uint8(QVSimpleStrategy.InternalRecipientStatus.Pending), uint8(recipientStatus));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        bytes memory data = __generateRecipientWithoutId(false);
        strategy.registerRecipient(data, msg.sender);
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(QVSimpleStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
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
        bytes memory data = __generateRecipientWithId(poolIdentity_anchor());

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

    // FIXME: this keeps returning INVALID_TOKEN()
    function test_setPayouts() public {
        // address recipientId = __register_accept_setPayout_recipient();
        // address[] memory recipients = new address[](1);
        // recipients[0] = recipientId;

        // IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, "", address(0));
        // assertEq(payouts[0].amount, 9.9e17);
        // assertEq(payouts[0].recipientAddress, makeAddr(string(abi.encodePacked("recipientAddress"))));
    }

    function test_isValidAllocator() public {
        assertFalse(strategy.isValidAllocator(address(0)));
        assertFalse(strategy.isValidAllocator(randomAddress()));
    }

    function test_reviewRecipients() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(false), sender);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Rejected;

        // FIXME:
        // vm.expectEmit(true, false, false, true);
        // emit RecipientStatusUpdated(recipientId, QVSimpleStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_manager1());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        QVSimpleStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(QVSimpleStrategy.InternalRecipientStatus.Rejected), uint8(recipient.recipientStatus));
    }

    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        vm.warp(allocationStartTime + 10);
        vm.expectRevert(QVSimpleStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.prank(pool_manager1());
        strategy.reviewRecipients(new address[](1), new QVSimpleStrategy.InternalRecipientStatus[](1));
    }

    function testRevert_reviewRecipients_INVALID() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(QVSimpleStrategy.INVALID.selector);
        vm.prank(pool_manager1());
        strategy.reviewRecipients(new address[](1), new QVSimpleStrategy.InternalRecipientStatus[](0));
    }

    function testRevert_reviewRecipients_withNoneStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.None;

        vm.expectRevert(abi.encodeWithSelector(QVSimpleStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_manager1());

        strategy.reviewRecipients(recipients, recipientStatuses);
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

    function testRevert_reviewRecipients_withAppealedStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Appealed;

        vm.expectRevert(abi.encodeWithSelector(QVSimpleStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_manager1());

        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.reviewRecipients(new address[](1), new QVSimpleStrategy.InternalRecipientStatus[](1));
    }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(false), sender);

        BaseStrategy.RecipientStatus receiptStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(receiptStatus));
    }

    function test_setMetadata() public {}

    function testRevert_setMetadata_UNAUTHORIZED() public {}

    function test_setPayout() public {}

    function testRevert_setPayout() public {}

    function test_allocate() public {}

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(false), recipient1());
        uint256 voiceCreditsToAllocate = 100;

        bytes memory data = abi.encode(recipientId, voiceCreditsToAllocate);

        vm.warp(allocationStartTime - 1);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        allo().allocate(poolId, data);
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

    function __generateRecipientWithoutId(bool _isUsingRegistryAnchor) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(recipient1(), _isUsingRegistryAnchor, metadata);
    }

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipient1(), metadata);
    }

    function __register_accept_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        address recipientId = strategy.registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_reject_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        address recipientId = strategy.registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVSimpleStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVSimpleStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVSimpleStrategy.InternalRecipientStatus.Rejected;
        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_accept_setPayout_recipient() internal returns (address) {
        address recipientId = __register_accept_recipient();
        vm.warp(registrationEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 9.9e17; // fund amount: 1e18 - fee: 1e17 = 9.9e17

        // fund pool
        allo().fundPool{value: 1e18}(poolId, 1e18, NATIVE);

        vm.warp(allocationEndTime + 10);

        vm.prank(pool_admin());
        strategy.getPayouts(recipientIds, "", address(0));

        return recipientId;
    }
}
