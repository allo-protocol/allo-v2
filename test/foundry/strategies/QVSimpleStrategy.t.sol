// SPDX-License Identifier: MIT
pragma solidity 0.8.19;

// Interfaces
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";

// Core/Strategies
import {QVSimpleStrategy} from "../../../contracts/strategies/qv-simple/QVSimpleStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";

import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test Helpers
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

// Mocks
import {MockERC20} from "../../utils/MockERC20.sol";

contract QVSimpleStrategyTest is StrategySetup, RegistrySetupFull, AlloSetup, EventSetup, Native {
    error ALLOCATION_NOT_ACTIVE();

    event AllocatorAdded(address indexed allocator, address sender);
    event AllocatorRemoved(address indexed allocator, address sender);
    event VoiceCreditsUpdated(address indexed allocator, uint256 voiceCredits, address sender);

    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        QVBaseStrategy.InternalRecipientStatus recipientStatus;
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

    address public strategy;
    MockERC20 public token;
    Metadata public poolMetadata;

    address[] public allowedTokens;

    uint256 public poolId;

    event Reviewed(address indexed recipientId, QVBaseStrategy.InternalRecipientStatus status, address sender);
    event RecipientStatusUpdated(
        address indexed recipientId, QVBaseStrategy.InternalRecipientStatus status, address sender
    );
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        MockERC20 token,
        uint256 amount,
        Metadata metadata
    );
    event Allocated(address indexed recipientId, uint256 votes, address allocator);

    function setUp() public virtual {
        _setUp();
        _initialize();
    }

    function _setUp() internal {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        token = new MockERC20();
        token.mint(address(this), 100e18);

        registrationStartTime = today();
        registrationEndTime = nextWeek();
        allocationStartTime = weekAfterNext();
        allocationEndTime = oneMonthFromNow();

        registryGating = false;
        metadataRequired = true;
        maxVoiceCreditsPerAllocator = 100;
        useRegistryAnchor = false;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
        strategy = address(new QVSimpleStrategy(address(allo()), "QVSimpleStrategy"));
    }

    function _initialize() internal virtual {
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
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

    function _createPoolWithCustomStrategy() internal virtual {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                registryGating,
                metadataRequired,
                2,
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

    function test_deployment() public virtual {
        assertEq(address(QVSimpleStrategy(strategy).getAllo()), address(allo()));
        assertEq(QVSimpleStrategy(strategy).getStrategyId(), keccak256(abi.encode("QVSimpleStrategy")));
    }

    function test_initialize() public virtual {
        assertEq(QVSimpleStrategy(strategy).getPoolId(), poolId);
        assertEq(QVSimpleStrategy(strategy).metadataRequired(), metadataRequired);
        assertEq(QVSimpleStrategy(strategy).maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
        assertEq(QVSimpleStrategy(strategy).registrationStartTime(), registrationStartTime);
        assertEq(QVSimpleStrategy(strategy).registrationEndTime(), registrationEndTime);
        assertEq(QVSimpleStrategy(strategy).allocationStartTime(), allocationStartTime);
        assertEq(QVSimpleStrategy(strategy).allocationEndTime(), allocationEndTime);
    }

    function test_initialize_BaseStrategy_UNAUTHORIZED() public {
        vm.prank(allo_owner());
        strategy = address(new QVSimpleStrategy(address(allo()), "QVSimpleStrategy"));
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public virtual {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        strategy = address(new QVSimpleStrategy(address(allo()), "QVSimpleStrategy"));

        // when registrationStartTime is in the past
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                today() - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when registrationStartTime > registrationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                weekAfterNext(),
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                oneMonthFromNow() + today(),
                allocationEndTime
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                oneMonthFromNow() + today(),
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function test_addAllocator() public {
        vm.prank(pool_manager1());
        address allocator = makeAddr("allocator");

        vm.expectEmit(false, false, false, true);
        emit AllocatorAdded(allocator, pool_manager1());

        QVSimpleStrategy(strategy).addAllocator(allocator);
    }

    function testRevert_addAllocator_BaseStrategy_UNAUTHORIZED() public {
        vm.prank(randomAddress());
        address allocator = makeAddr("allocator");

        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        QVSimpleStrategy(strategy).addAllocator(allocator);
    }

    function test_removeAllocator() public {
        vm.prank(pool_manager1());
        address allocator = makeAddr("allocator");

        vm.expectEmit(false, false, false, true);
        emit AllocatorRemoved(allocator, pool_manager1());

        QVSimpleStrategy(strategy).removeAllocator(allocator);
    }

    function testRevert_removeAllocator_BaseStrategy_UNAUTHORIZED() public {
        vm.prank(randomAddress());
        address allocator = makeAddr("allocator");

        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        QVSimpleStrategy(strategy).removeAllocator(allocator);
    }

    function test_registerRecipient_new() public {
        vm.warp(registrationStartTime + 10);
        address sender = recipient1();
        address recipientAddress = makeAddr("recipientAddress");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress, address(0), metadata);

        vm.prank(address(allo()));
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(data, sender);

        QVBaseStrategy.Recipient memory receipt = QVSimpleStrategy(strategy).getRecipient(recipientId);

        assertEq(receipt.useRegistryAnchor, useRegistryAnchor);
        assertEq(receipt.recipientAddress, recipientAddress);
        assertEq(receipt.metadata.pointer, metadata.pointer);
        assertEq(receipt.metadata.protocol, metadata.protocol);
        assertEq(uint8(receipt.recipientStatus), uint8(QVBaseStrategy.InternalRecipientStatus.Pending));
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        strategy = address(new QVSimpleStrategy(address(allo()), "QVSimpleStrategy"));
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(poolProfile_anchor());

        vm.prank(address(allo()));
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(data, pool_admin());

        QVBaseStrategy.Recipient memory receipt = QVSimpleStrategy(strategy).getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);
    }

    function test_registerRecipient_appeal() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager2());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // appeal
        bytes memory data = __generateRecipientWithoutId(false);
        vm.expectEmit(true, false, false, true);
        emit Appealed(recipientId, data, sender);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);

        // test status mapping. Internal: Appealed -> Global: Pending
        IStrategy.RecipientStatus newStatus = QVSimpleStrategy(strategy).getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(newStatus));
    }

    function test_getInternalRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        QVBaseStrategy.InternalRecipientStatus recipientStatus =
            QVSimpleStrategy(strategy).getInternalRecipientStatus(recipientId);
        assertEq(uint8(QVBaseStrategy.InternalRecipientStatus.Pending), uint8(recipientStatus));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        bytes memory data = __generateRecipientWithoutId(false);
        QVSimpleStrategy(strategy).registerRecipient(data, msg.sender);
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(QVBaseStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        QVSimpleStrategy(strategy).registerRecipient(data, recipient1());
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(QVBaseStrategy.UNAUTHORIZED.selector);

        bytes memory data = abi.encode(recipientAddress, true, metadata);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {
        strategy = address(new QVSimpleStrategy(address(allo()), "QVSimpleStrategy"));
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                2,
                maxVoiceCreditsPerAllocator,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(QVBaseStrategy.UNAUTHORIZED.selector);

        address sender = recipient1();
        bytes memory data = __generateRecipientWithId(poolProfile_anchor());

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, sender));

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();

        // pointer is empty
        vm.expectRevert(QVBaseStrategy.INVALID_METADATA.selector);
        address recipientAddress = recipient2();
        Metadata memory metadata = Metadata({protocol: 1, pointer: ""});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(QVBaseStrategy.INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).registerRecipient(data, sender);
    }

    function test_getPayouts() public {
        vm.warp(registrationStartTime + 10);
        address sender = recipient1();
        address recipientId = __register_accept_allocate_recipient();
        address[] memory recipientIds = new address[](2);

        recipientIds[0] = recipientId;
        recipientIds[1] = no_recipient();

        QVBaseStrategy.PayoutSummary[] memory payouts =
            QVSimpleStrategy(strategy).getPayouts(recipientIds, new bytes[](2));

        assertEq(payouts[0].recipientAddress, sender);
        assertEq(payouts[0].amount, 9.9e17);

        assertEq(payouts[1].recipientAddress, address(0));
        assertEq(payouts[1].amount, 0);
    }

    function test_getPayouts_ALREADY_DISTRIBUTED() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        assertEq(token.balanceOf(address(strategy)), 9.9e17);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).distribute(recipients, "", pool_admin());

        QVBaseStrategy.PayoutSummary[] memory payouts =
            QVSimpleStrategy(strategy).getPayouts(recipients, new bytes[](1));

        assertEq(payouts[0].recipientAddress, recipient1());
        assertEq(payouts[0].amount, 0); // already distributed
    }

    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10, pool_admin()
        );

        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );

        assertEq(QVSimpleStrategy(strategy).registrationStartTime(), registrationStartTime);
        assertEq(QVSimpleStrategy(strategy).registrationEndTime(), registrationEndTime);
        assertEq(QVSimpleStrategy(strategy).allocationStartTime(), allocationStartTime);
        assertEq(QVSimpleStrategy(strategy).allocationEndTime(), allocationEndTime + 10);
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        QVSimpleStrategy(strategy).updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).updatePoolTimestamps(
            block.timestamp - 1, registrationEndTime, allocationStartTime, allocationEndTime
        );
    }

    function test_isValidAllocator() public virtual {
        assertFalse(QVSimpleStrategy(strategy).isValidAllocator(address(0)));
        assertFalse(QVSimpleStrategy(strategy).isValidAllocator(randomAddress()));
    }

    function test_isPoolActive() public {
        vm.warp(registrationStartTime - 1);
        assertFalse(QVSimpleStrategy(strategy).isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(QVSimpleStrategy(strategy).isPoolActive());
    }

    function test_reviewRecipients() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        vm.expectEmit(true, false, false, false);
        emit RecipientStatusUpdated(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_manager2());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        QVBaseStrategy.Recipient memory recipient = QVSimpleStrategy(strategy).getRecipient(recipientId);
        assertEq(uint8(QVBaseStrategy.InternalRecipientStatus.Rejected), uint8(recipient.recipientStatus));
    }

    function test_reviewRecipient_reviewTreshold() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager1());

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // still pending
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Pending)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 1
        );

        vm.expectEmit(true, true, false, false);
        emit RecipientStatusUpdated(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager2());
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager2());

        vm.prank(pool_manager2());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // rejected
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2
        );

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // still rejected
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 3
        );
    }

    function test_reviewRecipient_reviewTreshold_noStatusChange() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // still pending
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Pending)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 1
        );

        vm.prank(pool_manager2());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // rejected
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2
        );

        // one accept after two rejects
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        // still rejected
        assertEq(
            uint8(QVSimpleStrategy(strategy).getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected)
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2
        );
        assertEq(
            QVSimpleStrategy(strategy).reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Accepted), 1
        );
    }

    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        vm.warp(allocationStartTime + 10);
        vm.expectRevert(QVBaseStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](1));
    }

    function testRevert_reviewRecipients_INVALID() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](0));
    }

    function testRevert_reviewRecipients_withNoneStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.None;

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_manager1());

        QVSimpleStrategy(strategy).reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_ReviewRecipients_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        address[] memory recipients = new address[](2);
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](2);

        recipients[0] = recipient1();
        recipients[1] = recipient2();

        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Accepted;
        recipientStatuses[1] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_notAManager());
        QVSimpleStrategy(strategy).reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_withAppealedStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Appealed;

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_manager1());

        QVSimpleStrategy(strategy).reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        QVSimpleStrategy(strategy).reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](1));
    }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(__generateRecipientWithoutId(false), sender);

        BaseStrategy.RecipientStatus receiptStatus = QVSimpleStrategy(strategy).getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(receiptStatus));
    }

    function test_allocate() public virtual {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        vm.warp(allocationStartTime + 10);

        QVSimpleStrategy(strategy).addAllocator(allocator);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.stopPrank();
        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, true);

        emit Allocated(recipientId, 2e9, allocator);

        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = __register_accept_recipient();
        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).addAllocator(randomAddress());

        vm.expectRevert(QVBaseStrategy.ALLOCATION_NOT_ACTIVE.selector);
        vm.prank(address(allo()));

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        QVSimpleStrategy(strategy).allocate(allocateData, randomAddress());
    }

    function testRevert_allocate_UNAUTHORIZED() public {
        address recipientId = __register_reject_recipient();
        address allocator = makeAddr("allocator");

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.UNAUTHORIZED.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        QVSimpleStrategy(strategy).addAllocator(allocator);

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.stopPrank();
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_tooManyVoiceCredits() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        QVSimpleStrategy(strategy).addAllocator(allocator);

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.INVALID.selector));
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 400);

        vm.stopPrank();

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_noVoiceTokens() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).addAllocator(allocator);
        bytes memory allocateData = __generateAllocation(recipientId, 0);

        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_voiceTokensMismatch() public {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        vm.warp(allocationStartTime + 10);

        QVSimpleStrategy(strategy).addAllocator(allocator);

        vm.expectRevert(QVBaseStrategy.INVALID.selector);

        vm.stopPrank();
        bytes memory allocateData = __generateAllocation(recipientId, 0);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);
    }

    function test_distribute() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        assertEq(token.balanceOf(address(strategy)), 9.9e17);

        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, false);

        // token.approve(pool_admin(), 100000000e18);
        emit Distributed(recipient1(), recipient1(), 9.9e17, pool_admin());

        QVSimpleStrategy(strategy).distribute(recipients, "", pool_admin());

        assertEq(token.balanceOf(recipient1()), 9.9e17);
    }

    function test_distribute_twice_to_same_recipient() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient1();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipient1()));

        QVSimpleStrategy(strategy).distribute(recipients, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_noRecipient() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = no_recipient();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipients[1]));

        QVSimpleStrategy(strategy).distribute(recipients, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_zeroAmount() public {
        __register_accept_recipient();

        vm.warp(allocationEndTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipients[0]));

        QVSimpleStrategy(strategy).distribute(recipients, "", pool_admin());
    }

    function test_calculateVotes() public {
        vm.warp(registrationStartTime + 10);
        address recipientId = __register_accept_allocate_recipient();

        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();
        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).addAllocator(allocator);

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocateData, allocator);

        uint256 votes = QVSimpleStrategy(strategy).sqrt(16);
        assertEq(votes, 4);
    }

    // Note: internal helper functions

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
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_reject_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        address recipientId = QVSimpleStrategy(strategy).registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;
        vm.prank(pool_admin());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_accept_allocate_recipient() internal returns (address) {
        address recipientId = __register_accept_recipient();
        vm.warp(registrationEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 9.9e17; // fund amount: 1e18 - fee: 1e17 = 9.9e17

        token.mint(pool_manager1(), 100e18);
        // set the allowance for the transfer
        vm.prank(pool_manager1());
        token.approve(address(allo()), 999999999e18);

        // fund pool
        vm.prank(pool_manager1());
        allo().fundPool(poolId, 1e18);

        vm.prank(pool_manager1());
        QVSimpleStrategy(strategy).addAllocator(randomAddress());

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 4);
        vm.prank(address(allo()));
        QVSimpleStrategy(strategy).allocate(allocation, randomAddress());

        vm.warp(allocationEndTime + 10);

        return recipientId;
    }

    function __generateAllocation(address _recipient, uint256 _amount) internal view virtual returns (bytes memory) {
        return abi.encode(_recipient, _amount);
    }
}
