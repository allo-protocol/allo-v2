pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/Allo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/donation-voting/DonationVotingStrategy.sol";
// Internal libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";

contract DonationVotingStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event RecipientStatusUpdated(
        address indexed recipientId, DonationVotingStrategy.InternalRecipientStatus recipientStatus, address sender
    );
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);
    event TimestampsUpdated(
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime,
        address sender
    );
    event PayoutSet(bytes recipientIds);

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    address[] public allowedTokens;

    DonationVotingStrategy public strategy;

    address public token;

    Metadata public poolMetadata;

    uint256 public poolId;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = block.timestamp + 10;
        registrationEndTime = block.timestamp + 300;
        allocationStartTime = block.timestamp + 301;
        allocationEndTime = block.timestamp + 600;

        useRegistryAnchor = false;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");

        allowedTokens = new address[](1);
        allowedTokens[0] = address(0);

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolIdentity_id(),
            address(strategy),
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DonationVotingStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        assertTrue(strategy.allowedTokens(address(0)));
    }

    function testRevert_initialize_withNoAllowedToken() public {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        // when _registrationStartTime is in past
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                new address[](0)
            )
        );
        assertTrue(strategy.allowedTokens(address(0)));
    }

    function test_initialize_BaseStrategy_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );
    }

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );
    }

    function testRevert_initialize_INVALID() public {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        // when _registrationStartTime is in past
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                block.timestamp - 1,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                block.timestamp,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _registrationStartTime > _allocationStartTime
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                block.timestamp,
                allocationEndTime,
                allowedTokens
            )
        );

        // when _allocationStartTime > _allocationEndTime
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                block.timestamp,
                allowedTokens
            )
        );

        // when  _registrationEndTime > _allocationEndTime
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                useRegistryAnchor,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                registrationStartTime - 1,
                allowedTokens
            )
        );
    }

    function test_getRecipient() public {
        vm.warp(registrationStartTime + 10);

        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientAddress = makeAddr("recipientAddress");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        address recipientId = strategy.registerRecipient(data, sender);

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(recipient.recipientAddress, recipientAddress);
    }

    function test_getInternalRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId("recipient", false), sender);

        DonationVotingStrategy.InternalRecipientStatus recipientStatus =
            strategy.getInternalRecipientStatus(recipientId);
        assertEq(uint8(DonationVotingStrategy.InternalRecipientStatus.Pending), uint8(recipientStatus));
    }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId("recipient", false), sender);

        BaseStrategy.RecipientStatus recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(recipientStatus));
    }

    function test_getRecipientStatus_appeal() public {
        address sender = makeAddr("recipient");
        address recipientId = __register_reject_recipient("recipient");

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        bytes memory data = __generateRecipientWithoutId("recipient", false);
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);

        BaseStrategy.RecipientStatus recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.RecipientStatus.Pending), uint8(recipientStatus));
    }

    function test_getPayouts() public {
        address recipientId = __register_accept_setPayout_recipient();
        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, "", address(0));
        assertEq(payouts[0].amount, 9.9e17);
        assertEq(payouts[0].recipientAddress, makeAddr(string(abi.encodePacked("recipientAddress"))));
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(address(0)));
        assertTrue(strategy.isValidAllocator(makeAddr("random")));
    }

    function test_reviewRecipients() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId("recipient", false), sender);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.Rejected;

        vm.expectEmit(true, false, false, true);
        emit RecipientStatusUpdated(recipientId, DonationVotingStrategy.InternalRecipientStatus.Rejected, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(DonationVotingStrategy.InternalRecipientStatus.Rejected), uint8(recipient.recipientStatus));
    }

    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(DonationVotingStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.prank(pool_admin());
        strategy.reviewRecipients(new address[](1), new DonationVotingStrategy.InternalRecipientStatus[](1));
    }

    function testRevert_reviewRecipients_INVALID() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.reviewRecipients(new address[](1), new DonationVotingStrategy.InternalRecipientStatus[](0));
    }

    function testRevert_reviewRecipients_withNoneStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.None;

        vm.expectRevert(abi.encodeWithSelector(DonationVotingStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_admin());

        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_withAppealedStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr("recipient");

        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.Appealed;

        vm.expectRevert(abi.encodeWithSelector(DonationVotingStrategy.RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_admin());

        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.reviewRecipients(new address[](1), new DonationVotingStrategy.InternalRecipientStatus[](1));
    }

    function test_setPayout() public {
        address recipientId = __register_accept_recipient();
        vm.warp(registrationEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 9.9e17; // 1e17 pool amount - 1e17 fee

        vm.warp(allocationEndTime + 10);
        // fund pool
        allo().fundPool{value: 1e18}(poolId, 1e18, NATIVE);

        vm.prank(pool_admin());

        vm.expectEmit(false, false, false, true);
        emit PayoutSet(abi.encode(recipientIds));

        strategy.setPayout(recipientIds, amounts);
    }

    function testRevert_setPayout_BaseStrategy_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(makeAddr("random"));
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    function testRevert_setPayout_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(DonationVotingStrategy.ALLOCATION_NOT_ENDED.selector);
        vm.prank(pool_admin());
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    function testRevert_setPayout_INVALID_rejectedApplication() public {
        address recipientId = __register_reject_recipient("recipient");
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        vm.expectRevert(DonationVotingStrategy.INVALID.selector);

        vm.prank(pool_admin());
        vm.warp(allocationEndTime + 10);
        strategy.setPayout(recipientIds, amounts);
    }

    function testRevert_setPayout_INVALID_mismatchLength() public {
        vm.warp(allocationEndTime + 10);
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    // todo: what is this test testing?
    function testRevert_setPayout_RECIPIENT_ERROR() public {
        address recipientId = __register_accept_setPayout_recipient();

        address sender = makeAddr("recipient");
        vm.expectRevert(abi.encodeWithSelector(DonationVotingStrategy.RECIPIENT_ERROR.selector, sender));

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 9.9e17; // fund amount: 1e18 - fee: 1e17 = 9.9e17

        vm.prank(pool_admin());
        strategy.setPayout(recipientIds, amounts);
    }

    function testRevert_setPayout_INVALID_amountExceeded() public {
        address recipientId = __register_accept_recipient();
        vm.warp(registrationEndTime + 10);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.warp(allocationEndTime + 10);
        vm.prank(pool_admin());
        strategy.setPayout(recipientIds, amounts);
    }

    function test_claim() public {
        // TODO
    }

    function testRevert_claim() public {
        // TODO
    }

    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10, pool_admin()
        );

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );

        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime + 10);
    }

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(block.timestamp - 1, registrationEndTime, allocationStartTime, allocationEndTime);
    }

    function test_withdraw() public {
        // TODO: ADD
    }

    function testRevert_withdraw_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(DonationVotingStrategy.ALLOCATION_NOT_ENDED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(DonationVotingStrategy.NOT_ALLOWED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_NOT_ALLOWED_exceed_amount() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(DonationVotingStrategy.NOT_ALLOWED.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.withdraw(1e18);
    }

    function test_isPoolActive() public {
        assertFalse(strategy.isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(strategy.isPoolActive());
    }

    function test_registerRecipient_new() public {
        vm.warp(registrationStartTime + 1);
        address sender = makeAddr("recipient");
        address recipientAddress = makeAddr("recipientAddress");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.expectEmit(true, false, false, true);
        emit Registered(sender, data, sender);

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(recipient.recipientStatus), uint8(DonationVotingStrategy.InternalRecipientStatus.Pending));
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        vm.warp(registrationStartTime + 1);
        bytes memory data = __generateRecipientWithId(poolIdentity_anchor());

        vm.expectEmit(true, false, false, true);
        emit Registered(poolIdentity_anchor(), data, address(pool_admin()));

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, pool_admin());

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(DonationVotingStrategy.InternalRecipientStatus.Pending), uint8(recipient.recipientStatus));
    }

    function test_registerRecipient_appeal() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = makeAddr("recipient");
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId("recipient", false), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.Rejected;

        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        // appeal
        bytes memory data = __generateRecipientWithoutId("recipient", false);
        vm.expectEmit(true, false, false, true);
        emit Appealed(recipientId, data, sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        bytes memory data = __generateRecipientWithoutId("recipient", false);
        strategy.registerRecipient(data, msg.sender);
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(DonationVotingStrategy.REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId("recipient", false);
        strategy.registerRecipient(data, makeAddr("recipient"));
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 1);

        address sender = makeAddr("recipient");
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(DonationVotingStrategy.UNAUTHORIZED.selector);

        bytes memory data = abi.encode(recipientAddress, true, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_withAnchorGating_UNAUTHORIZED() public {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                true,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(DonationVotingStrategy.UNAUTHORIZED.selector);

        address sender = makeAddr("recipient");
        bytes memory data = __generateRecipientWithId(sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 1);

        address sender = makeAddr("recipient");
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(abi.encodeWithSelector(DonationVotingStrategy.RECIPIENT_ERROR.selector, sender));

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.warp(registrationStartTime + 1);

        address sender = makeAddr("recipient");

        // pointer is empty
        vm.expectRevert(DonationVotingStrategy.INVALID_METADATA.selector);
        address recipientAddress = makeAddr("recipientAddress");
        Metadata memory metadata = Metadata({protocol: 1, pointer: ""});

        bytes memory data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(DonationVotingStrategy.INVALID_METADATA.selector);
        metadata = Metadata({protocol: 0, pointer: "metadata"});

        data = abi.encode(recipientAddress, false, metadata);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function test_allocate() public {
        address recipientId = __register_accept_recipient();

        vm.warp(allocationStartTime + 10);

        bytes memory allocateData = abi.encode(recipientId, 1e15, NATIVE);

        address allocator = makeAddr("allocator");
        deal(allocator, 1e18);
        deal(address(allo()), 1e18);

        vm.expectEmit(true, false, false, true);
        emit Allocated(recipientId, 1e15, NATIVE, allocator);

        vm.prank(address(allo()));
        strategy.allocate{value: 1e15}(allocateData, allocator);
    }

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        address recipientId = __register_accept_recipient();

        vm.expectRevert(DonationVotingStrategy.ALLOCATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        strategy.allocate(allocateData, msg.sender);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient("recipient");

        vm.expectRevert(abi.encodeWithSelector(DonationVotingStrategy.RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate(allocateData, msg.sender);
    }

    function testRevert_allocate_INVALID_invalidToken() public {
        allowedTokens = new address[](1);
        allowedTokens[0] = makeAddr("token");

        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                false,
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        address recipientId = __register_accept_recipient();
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);

        vm.warp(allocationStartTime + 10);

        address allocator = makeAddr("allocator");
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate(allocateData, allocator);
    }

    function testRevert_allocate_INVALID_amountMismatch() public {
        address allocator = makeAddr("allocator");
        deal(address(allo()), 1e18);

        address recipientId = __register_accept_recipient();

        vm.warp(allocationStartTime + 10);
        vm.expectRevert(DonationVotingStrategy.INVALID.selector);

        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate{value: 1e17}(allocateData, allocator);
    }

    function test_distribute() public {
        // TODO
    }

    function test_distribute_twice_to_same_recipient() public {
        // TODO
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        // TODO
    }

    function __generateRecipientWithoutId(string memory _recipientId, bool _isUsingRegistryAnchor)
        internal
        returns (bytes memory)
    {
        address recipientAddress = makeAddr(string(abi.encodePacked("recipientAddress")));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(recipientAddress, _isUsingRegistryAnchor, metadata);
    }

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        address recipientAddress = makeAddr(string(abi.encodePacked("recipientAddress", _recipientId)));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress, metadata);
    }

    function __register_accept_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId("recipient", false);
        address recipientId = strategy.registerRecipient(data, makeAddr("recipient"));

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.Accepted;
        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_reject_recipient(string memory recipient) internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId("recipient", false);
        address recipientId = strategy.registerRecipient(data, makeAddr(recipient));

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        DonationVotingStrategy.InternalRecipientStatus[] memory recipientStatuses =
            new DonationVotingStrategy.InternalRecipientStatus[](1);
        recipientStatuses[0] = DonationVotingStrategy.InternalRecipientStatus.Rejected;
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
        strategy.setPayout(recipientIds, amounts);

        return recipientId;
    }
}
