pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/_poc/donation-voting/DonationVotingStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

import {EventSetup} from "../shared/EventSetup.sol";

contract DonationVotingStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    event UpdatedRegistration(
        address indexed recipientId, bytes data, address sender, DonationVotingStrategy.Status status
    );
    event RecipientStatusUpdated(
        address indexed recipientId, DonationVotingStrategy.Status recipientStatus, address sender
    );

    error AMOUNT_MISMATCH();

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    address[] public allowedTokens;

    DonationVotingStrategy public strategy;

    address public token;

    Metadata public poolMetadata;

    uint256 public poolId;

    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);
        allocationStartTime = uint64(block.timestamp + 301);
        allocationEndTime = uint64(block.timestamp + 600);

        useRegistryAnchor = false;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");

        allowedTokens = new address[](1);
        allowedTokens[0] = address(0);

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
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

    function testRevert_initialize_withNoAllowedToken() public virtual {
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

    function test_initialize_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

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

    function testRevert_initialize_ALREADY_INITIALIZED() public virtual {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

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

    function testRevert_initialize_INVALID() public virtual {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        // when _registrationStartTime is in past
        vm.expectRevert(INVALID.selector);
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
        vm.expectRevert(INVALID.selector);
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
        vm.expectRevert(INVALID.selector);
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
        vm.expectRevert(INVALID.selector);
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
        vm.expectRevert(INVALID.selector);
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
        address sender = recipient();
        address recipientAddress = recipientAddress();

        bytes memory data = __getEncodedData(recipientAddress, 1, "metadata");

        address recipientId = strategy.registerRecipient(data, sender);

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(recipient.recipientAddress, recipientAddress);
    }

    function test_getRecipientStatus() public {
        vm.warp(registrationStartTime + 10);
        vm.prank(address(allo()));
        address sender = recipient();
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(), sender);

        BaseStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.Status.Pending), uint8(recipientStatus));
    }

    function test_getRecipientStatus_appeal() public {
        address sender = recipient();
        address recipientId = __register_reject_recipient();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        bytes memory data = __generateRecipientWithoutId();
        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);

        BaseStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.Status.Pending), uint8(recipientStatus));
    }

    function test_getPayouts() public {
        address recipientId = __register_accept_setPayout_recipient();
        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.PayoutSummary[] memory payouts = strategy.getPayouts(recipients, new bytes[](1));
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
        address sender = recipient();
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(), sender);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        DonationVotingStrategy.Status[] memory recipientStatuses = new DonationVotingStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Rejected;

        vm.expectEmit(true, false, false, true);
        emit RecipientStatusUpdated(recipientId, IStrategy.Status.Rejected, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Rejected), uint8(recipient.recipientStatus));
    }

    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);
        vm.prank(pool_admin());
        strategy.reviewRecipients(new address[](1), new IStrategy.Status[](1));
    }

    function testRevert_reviewRecipients_INVALID() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.reviewRecipients(new address[](1), new IStrategy.Status[](0));
    }

    function testRevert_reviewRecipients_withNoneStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = recipient();

        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.None;

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_admin());

        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_withAppealedStatus_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 10);

        address[] memory recipients = new address[](1);
        recipients[0] = recipient();

        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Appealed;

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipients[0]));
        vm.prank(pool_admin());

        strategy.reviewRecipients(recipients, recipientStatuses);
    }

    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.reviewRecipients(new address[](1), new IStrategy.Status[](1));
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
        allo().fundPool{value: 1e18}(poolId, 1e18);

        vm.prank(pool_admin());

        vm.expectEmit(false, false, false, true);
        emit PayoutSet(abi.encode(recipientIds));

        strategy.setPayout(recipientIds, amounts);
    }

    function testRevert_setPayout_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(makeAddr("random"));
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    function testRevert_setPayout_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);
        vm.prank(pool_admin());
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    function testRevert_setPayout_INVALID_rejectedApplication() public {
        address recipientId = __register_reject_recipient();
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        vm.expectRevert(INVALID.selector);

        vm.prank(pool_admin());
        vm.warp(allocationEndTime + 10);
        strategy.setPayout(recipientIds, amounts);
    }

    function testRevert_setPayout_INVALID_mismatchLength() public {
        vm.warp(allocationEndTime + 10);
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.setPayout(new address[](1), new uint256[](2));
    }

    function testRevert_setPayout_RECIPIENT_ERROR() public {
        address recipientId = __register_accept_setPayout_recipient();

        address sender = recipient();
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, sender));

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

        vm.expectRevert(INVALID.selector);
        vm.warp(allocationEndTime + 10);
        vm.prank(pool_admin());
        strategy.setPayout(recipientIds, amounts);
    }

    function test_claim() public {
        __register_accept_recipient();

        bytes memory allocateData = abi.encode(recipient(), 1e15, NATIVE);

        address allocator = randomAddress();
        deal(address(allo()), 1e18);

        vm.warp(allocationStartTime + 10);
        vm.prank(address(allo()));

        strategy.allocate{value: 1e15}(allocateData, allocator);

        DonationVotingStrategy.Claim[] memory claim = new DonationVotingStrategy.Claim[](1);
        claim[0] = DonationVotingStrategy.Claim({recipientId: recipient(), token: NATIVE});

        vm.warp(allocationEndTime + 10);

        vm.expectEmit(true, false, false, true);
        emit Claimed(recipient(), recipientAddress(), 1e15, NATIVE);

        strategy.claim(claim);

        assertEq(address(recipientAddress()).balance, 1e15);
    }

    function testRevert_claim() public {
        __register_accept_recipient();

        bytes memory allocateData = abi.encode(recipient(), 1e15, NATIVE);

        address allocator = randomAddress();
        deal(address(allo()), 1e18);

        vm.warp(allocationStartTime + 10);
        vm.prank(address(allo()));

        strategy.allocate{value: 1e15}(allocateData, allocator);

        DonationVotingStrategy.Claim[] memory claim = new DonationVotingStrategy.Claim[](1);
        claim[0] = DonationVotingStrategy.Claim({recipientId: no_recipient(), token: NATIVE});

        vm.warp(allocationEndTime + 10);
        vm.expectRevert(INVALID.selector);

        strategy.claim(claim);
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
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            uint64(block.timestamp - 1), registrationEndTime, allocationStartTime, allocationEndTime
        );
    }

    function test_withdraw() public {
        allo().fundPool{value: 1e18}(poolId, 1e18);
        vm.warp(allocationEndTime + 31 days);
        vm.prank(pool_admin());
        strategy.withdraw(9.9e17); // 1e18 - 1e17 fee = 9.9e17
    }

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(allocationEndTime + 1 days);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_NOT_ALLOWED_exceed_amount() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
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
        address sender = recipient();
        bytes memory data = __getEncodedData(sender, 1, "metadata");

        vm.expectEmit(true, false, false, true);
        emit Registered(sender, data, sender);

        assertEq(uint8(strategy.getRecipient(sender).recipientStatus), uint8(IStrategy.Status.None));

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, sender);

        DonationVotingStrategy.Recipient memory _recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(_recipient.recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function test_registerRecipient_new_withRegistryAnchor() public {
        strategy = new DonationVotingStrategy(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingStrategy.InitializeData(
                    true,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        vm.warp(registrationStartTime + 1);
        bytes memory data = __generateRecipientWithId(poolProfile_anchor());

        vm.expectEmit(true, false, false, true);
        emit Registered(poolProfile_anchor(), data, address(pool_admin()));

        vm.prank(address(allo()));
        address recipientId = strategy.registerRecipient(data, pool_admin());

        DonationVotingStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertEq(uint8(IStrategy.Status.Pending), uint8(recipient.recipientStatus));
    }

    function test_registerRecipient_accepted() public {
        address recipientId = __register_accept_recipient();

        assertEq(uint8(strategy.getRecipient(recipientId).recipientStatus), uint8(IStrategy.Status.Accepted));

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId();
        strategy.registerRecipient(data, recipient());

        assertEq(uint8(strategy.getRecipient(recipientId).recipientStatus), uint8(IStrategy.Status.Pending));
    }

    function test_registerRecipient_appeal() public {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        address sender = recipient();
        address recipientId = strategy.registerRecipient(__generateRecipientWithoutId(), sender);

        // reject
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Rejected;

        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        assertEq(uint8(strategy.getRecipient(recipientId).recipientStatus), uint8(IStrategy.Status.Rejected));

        // appeal
        bytes memory data = __generateRecipientWithoutId();
        vm.expectEmit(true, false, false, true);
        emit UpdatedRegistration(recipientId, data, sender, IStrategy.Status.Appealed);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        bytes memory data = __generateRecipientWithoutId();
        strategy.registerRecipient(data, msg.sender);
    }

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(registrationEndTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId();
        strategy.registerRecipient(data, recipient());
    }

    function testRevert_registerRecipient_isUsingRegistryAnchor_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient();
        address recipientAddress = address(0);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(UNAUTHORIZED.selector);

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
                DonationVotingStrategy.InitializeData(
                    true,
                    metadataRequired,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    allowedTokens
                )
            )
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(UNAUTHORIZED.selector);

        address sender = recipient();
        bytes memory data = __generateRecipientWithId(sender);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient();
        address recipientAddress = address(0);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, sender));

        bytes memory data = __getEncodedData(recipientAddress, 1, "metadata");

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.warp(registrationStartTime + 1);

        address sender = recipient();

        // pointer is empty
        vm.expectRevert(INVALID_METADATA.selector);
        address recipientAddress = recipientAddress();
        bytes memory data = __getEncodedData(recipientAddress, 1, "");

        vm.prank(address(allo()));
        strategy.registerRecipient(data, sender);

        // protocol is 0
        vm.expectRevert(INVALID_METADATA.selector);
        data = __getEncodedData(recipientAddress, 0, "metadata");

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

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        strategy.allocate(allocateData, msg.sender);
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_reject_recipient();

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        vm.warp(allocationStartTime + 10);
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate(allocateData, msg.sender);
    }

    function testRevert_allocate_INVALID_invalidToken() public virtual {
        address[] memory allowedTokens_ = new address[](1);
        allowedTokens_[0] = makeAddr("token");

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
                allowedTokens_
            )
        );

        address recipientId = __register_accept_recipient();
        vm.expectRevert(INVALID.selector);

        vm.warp(allocationStartTime + 10);

        address allocator = makeAddr("allocator");
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate(allocateData, allocator);
    }

    function testRevert_allocate_AMOUNT_MISMATCH() public {
        address allocator = makeAddr("allocator");
        deal(address(allo()), 1e18);

        address recipientId = __register_accept_recipient();

        vm.warp(allocationStartTime + 10);
        vm.expectRevert(AMOUNT_MISMATCH.selector);

        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate{value: 1e17}(allocateData, allocator);
    }

    function test_distribute() public {
        __register_accept_setPayout_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient();

        vm.prank(address(allo()));
        vm.expectEmit(true, false, false, true);

        emit Distributed(recipient(), recipientAddress(), 9.9e17, pool_admin());

        strategy.distribute(recipients, "", pool_admin());

        assertEq(address(recipientAddress()).balance, 9.9e17);
    }

    function testRevert_distribute_twice_to_same_recipient() public {
        __register_accept_setPayout_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient();
        recipients[1] = recipient();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(INVALID.selector));

        strategy.distribute(recipients, "", pool_admin());
    }

    function testRevert_distribute_RECIPIENT_ERROR() public {
        __register_accept_setPayout_recipient();

        address[] memory recipients = new address[](2);
        recipients[0] = recipient();
        recipients[1] = no_recipient();

        vm.prank(address(allo()));
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipients[1]));

        strategy.distribute(recipients, "", pool_admin());
    }

    function __generateRecipientWithoutId() internal returns (bytes memory) {
        return __getEncodedData(recipientAddress(), 1, "metadata");
    }

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress(), metadata);
    }

    function __register_accept_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId();
        address recipientId = strategy.registerRecipient(data, recipient());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Accepted;
        vm.prank(pool_admin());
        strategy.reviewRecipients(recipientIds, recipientStatuses);

        return recipientId;
    }

    function __register_reject_recipient() internal returns (address) {
        vm.warp(registrationStartTime + 10);

        // register
        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithoutId();
        address recipientId = strategy.registerRecipient(data, recipient());

        // accept
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;
        IStrategy.Status[] memory recipientStatuses = new IStrategy.Status[](1);
        recipientStatuses[0] = IStrategy.Status.Rejected;
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
        allo().fundPool{value: 1e18}(poolId, 1e18);

        vm.warp(allocationEndTime + 10);

        vm.prank(pool_admin());
        strategy.setPayout(recipientIds, amounts);

        return recipientId;
    }

    function __getEncodedData(address _recipientAddress, uint256 _protocol, string memory _pointer)
        internal
        virtual
        returns (bytes memory data)
    {
        Metadata memory metadata = Metadata({protocol: _protocol, pointer: _pointer});
        data = abi.encode(_recipientAddress, false, metadata);
    }
}
