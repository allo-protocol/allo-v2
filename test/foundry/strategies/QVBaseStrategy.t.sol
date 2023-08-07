pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/Allo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {QVBaseStrategy} from "../../../contracts/strategies/qv-base/QVBaseStrategy.sol";
// Internal libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {BaseStrategyTestMock} from "../../utils/BaseStrategyTestMock.sol";
import {MockERC20} from "../../utils/MockERC20.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {StrategySetup} from "../shared/StrategySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract QVBaseStrategyTest is Test, AlloSetup, RegistrySetupFull, StrategySetup, EventSetup {
    error ALLOCATION_NOT_ACTIVE();

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

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    address internal _strategy;
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

    function setUp() public {
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
        useRegistryAnchor = false;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        _strategy = address(new BaseStrategyTestMock(address(allo()), "MockStrategy"));
        _initialize();
    }

    function _initialize() internal virtual {
        vm.prank(address(allo()));
        qvStrategy().initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
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
            _strategy,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
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
        assertEq(address(qvStrategy().getAllo()), address(allo()));
        assertEq(qvStrategy().getStrategyId(), keccak256(abi.encode("MockStrategy")));
    }

    function test_initialize() public virtual {
        assertEq(qvStrategy().getPoolId(), poolId);
        assertEq(qvStrategy().metadataRequired(), metadataRequired);
        assertEq(qvStrategy().registrationStartTime(), registrationStartTime);
        assertEq(qvStrategy().registrationEndTime(), registrationEndTime);
        assertEq(qvStrategy().allocationStartTime(), allocationStartTime);
        assertEq(qvStrategy().allocationEndTime(), allocationEndTime);
    }

    function test_initialize_UNAUTHORIZED() public {
        vm.prank(allo_owner());
        address strategy = address(new BaseStrategyTestMock(address(allo()), "MockStrategy"));
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        BaseStrategyTestMock(strategy).initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public virtual {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        qvStrategy().initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        BaseStrategyTestMock strategy = new BaseStrategyTestMock(address(allo()), "MockStrategy");

        // when registrationStartTime is in the past
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                today() - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );
        // when registrationStartTime > registrationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                weekAfterNext(),
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        // when allocationStartTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
                registrationStartTime,
                registrationEndTime,
                oneMonthFromNow() + today(),
                allocationEndTime
            )
        );

        // when  registrationEndTime > allocationEndTime
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                registryGating,
                metadataRequired,
                2,
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

        bytes memory data = abi.encode(recipientAddress, address(0), metadata);

        vm.prank(address(allo()));
        address recipientId = qvStrategy().registerRecipient(data, sender);

        QVBaseStrategy.Recipient memory receipt = qvStrategy().getRecipient(recipientId);

        assertEq(receipt.useRegistryAnchor, useRegistryAnchor);
        assertEq(receipt.recipientAddress, recipientAddress);
        assertEq(receipt.metadata.pointer, metadata.pointer);
        assertEq(receipt.metadata.protocol, metadata.protocol);
        assertEq(uint8(receipt.recipientStatus), uint8(QVBaseStrategy.InternalRecipientStatus.Pending));
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        BaseStrategyTestMock strategy = new BaseStrategyTestMock(address(allo()), "MockStrategy");
        vm.prank(address(allo()));
        BaseStrategyTestMock(strategy).initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                2,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime
            )
        );

        vm.warp(registrationStartTime + 10);
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, profile1_member1());

        QVBaseStrategy.Recipient memory receipt = BaseStrategyTestMock(strategy).getRecipient(recipientId);
        assertTrue(receipt.useRegistryAnchor);
    }

    function test_registerRecipient_appeal() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager2());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // appeal
        bytes memory data = __generateRecipientWithoutId(false);
        vm.expectEmit(true, false, false, true);
        emit Appealed(recipientId, data, sender);

        vm.prank(address(allo()));
        qvStrategy().registerRecipient(data, sender);

        // test status mapping. Internal: Appealed -> Global: Pending
        IStrategy.RecipientStatus newStatus = qvStrategy().getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(newStatus));
    }

    function test_getInternalRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        QVBaseStrategy.InternalRecipientStatus recipientStatus = qvStrategy().getInternalRecipientStatus(recipientId);
        assertEq(uint8(QVBaseStrategy.InternalRecipientStatus.Pending), uint8(recipientStatus));
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(QVBaseStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        qvStrategy().registerRecipient(data, recipient1());
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(QVBaseStrategy.UNAUTHORIZED.selector);

        bytes memory data = abi.encode(recipientAddress, true, metadata);

        vm.prank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {
        BaseStrategyTestMock strategy = new BaseStrategyTestMock(address(allo()), "MockStrategy");
        vm.prank(address(allo()));
        BaseStrategyTestMock(strategy).initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                2,
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
        qvStrategy().registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient1();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, sender));

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
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
        qvStrategy().registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(QVBaseStrategy.INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        qvStrategy().registerRecipient(data, sender);
    }

    function test_getPayouts() public {
        vm.warp(registrationStartTime + 10);
        address sender = recipient1();
        address recipientId = __register_accept_allocate_recipient();
        address[] memory recipientIds = new address[](2);

        recipientIds[0] = recipientId;
        recipientIds[1] = no_recipient();

        QVBaseStrategy.PayoutSummary[] memory payouts = qvStrategy().getPayouts(recipientIds, new bytes[](2));

        assertEq(payouts[0].recipientAddress, sender);
        assertEq(payouts[0].amount, 9.9e17);

        assertEq(payouts[1].recipientAddress, address(0));
        assertEq(payouts[1].amount, 0);
    }

    function test_getPayouts_ALREADY_DISTRIBUTED() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        assertEq(token.balanceOf(_strategy), 9.9e17);

        vm.prank(address(allo()));
        qvStrategy().distribute(recipients, "", pool_admin());

        QVBaseStrategy.PayoutSummary[] memory payouts = qvStrategy().getPayouts(recipients, new bytes[](1));

        assertEq(payouts[0].recipientAddress, recipient1());
        assertEq(payouts[0].amount, 0); // already distributed
    }

    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10, pool_admin()
        );

        vm.prank(pool_admin());
        qvStrategy().updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );

        assertEq(qvStrategy().registrationStartTime(), registrationStartTime);
        assertEq(qvStrategy().registrationEndTime(), registrationEndTime);
        assertEq(qvStrategy().allocationStartTime(), allocationStartTime);
        assertEq(qvStrategy().allocationEndTime(), allocationEndTime + 10);
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        qvStrategy().updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(pool_admin());
        qvStrategy().updatePoolTimestamps(
            block.timestamp - 1, registrationEndTime, allocationStartTime, allocationEndTime
        );
    }

    function test_isPoolActive() public {
        vm.warp(registrationStartTime - 1);
        assertFalse(qvStrategy().isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(qvStrategy().isPoolActive());
    }

    function test_reviewRecipients() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        vm.expectEmit(true, false, false, false);
        emit RecipientStatusUpdated(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_manager2());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        QVBaseStrategy.Recipient memory recipient = qvStrategy().getRecipient(recipientId);
        assertEq(uint8(QVBaseStrategy.InternalRecipientStatus.Rejected), uint8(recipient.recipientStatus));
    }

    function test_reviewRecipient_reviewTreshold() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager1());

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // still pending
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Pending));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 1);

        vm.expectEmit(true, true, false, false);
        emit RecipientStatusUpdated(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager2());
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_manager2());

        vm.prank(pool_manager2());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // rejected
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2);

        vm.expectEmit(true, false, false, false);
        emit Reviewed(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_admin());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // still rejected
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 3);
    }

    function test_reviewRecipient_reviewTreshold_noStatusChange() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // still pending
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Pending));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 1);

        vm.prank(pool_manager2());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // rejected
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2);

        // one accept after two rejects
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        // still rejected
        assertEq(uint8(qvStrategy().getRecipientStatus(recipientId)), uint8(IStrategy.RecipientStatus.Rejected));
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Rejected), 2);
        assertEq(qvStrategy().reviewsByStatus(recipientId, QVBaseStrategy.InternalRecipientStatus.Accepted), 1);
    }

    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        vm.warp(allocationStartTime + 10);
        vm.expectRevert(QVBaseStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](1));
    }

    function testRevert_reviewRecipients_INVALID() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(QVBaseStrategy.INVALID.selector);
        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](0));
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

        qvStrategy().reviewRecipients(recipients, recipientStatuses);
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
        qvStrategy().reviewRecipients(recipients, recipientStatuses);
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

        qvStrategy().reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        qvStrategy().reviewRecipients(new address[](1), new QVBaseStrategy.InternalRecipientStatus[](1));
    }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient1();
        address recipientId = qvStrategy().registerRecipient(__generateRecipientWithoutId(false), sender);

        BaseStrategy.RecipientStatus receiptStatus = qvStrategy().getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(receiptStatus));
    }

    function test_allocate() public virtual {
        address recipientId = __register_accept_recipient();
        address allocator = randomAddress();

        vm.startPrank(pool_manager2());
        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        vm.stopPrank();
        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, true);

        emit Allocated(recipientId, 2e9, allocator);

        qvStrategy().allocate(allocateData, allocator);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = __register_accept_recipient();

        vm.expectRevert(QVBaseStrategy.ALLOCATION_NOT_ACTIVE.selector);
        vm.prank(address(allo()));

        bytes memory allocateData = __generateAllocation(recipientId, 4);
        qvStrategy().allocate(allocateData, randomAddress());
    }

    function test_distribute() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        assertEq(token.balanceOf(address(qvStrategy())), 9.9e17);

        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, false);

        // token.approve(pool_admin(), 100000000e18);
        emit Distributed(recipient1(), recipient1(), 9.9e17, pool_admin());

        qvStrategy().distribute(recipients, "", pool_admin());

        assertEq(token.balanceOf(recipient1()), 9.9e17);
    }

    function test_distribute_twice_to_same_recipient() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = recipient1();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipient1()));

        qvStrategy().distribute(recipients, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_noRecipient() public {
        __register_accept_allocate_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient1();
        recipients[1] = no_recipient();

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, no_recipient()));

        vm.prank(address(allo()));
        qvStrategy().distribute(recipients, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR_zeroAmount() public {
        __register_accept_recipient();

        vm.warp(allocationEndTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = recipient1();

        vm.expectRevert(abi.encodeWithSelector(QVBaseStrategy.RECIPIENT_ERROR.selector, recipients[0]));

        vm.prank(address(allo()));
        qvStrategy().distribute(recipients, "", pool_admin());
    }

    function test_calculateVotes() public {
        vm.warp(registrationStartTime + 10);
        address recipientId = __register_accept_allocate_recipient();

        vm.warp(allocationStartTime + 10);

        address allocator = randomAddress();

        bytes memory allocateData = __generateAllocation(recipientId, 4);

        vm.prank(address(allo()));
        qvStrategy().allocate(allocateData, allocator);

        uint256 votes = qvStrategy().sqrt(16);
        assertEq(votes, 4);
    }

    function test_mock_isValidAllocator() public {
      assertTrue(qvStrategy().isValidAllocator(address(123)));
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
        address recipientId = qvStrategy().registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_reject_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId(false);
        address recipientId = qvStrategy().registerRecipient(data, recipient1());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        QVBaseStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new QVBaseStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = QVBaseStrategy.InternalRecipientStatus.Rejected;
        vm.prank(pool_admin());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

        vm.prank(pool_manager1());
        qvStrategy().reviewRecipients(recipientIds, recipientStatuses);

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

        vm.warp(allocationStartTime + 10);
        bytes memory allocation = __generateAllocation(recipientId, 4);
        vm.prank(address(allo()));
        qvStrategy().allocate(allocation, randomAddress());

        vm.warp(allocationEndTime + 10);

        return recipientId;
    }

    function __generateAllocation(address _recipient, uint256 _amount) internal view virtual returns (bytes memory) {
        return abi.encode(_recipient, _amount);
    }

    function qvStrategy() internal view virtual returns (QVBaseStrategy) {
        return (QVBaseStrategy(_strategy));
    }
}
