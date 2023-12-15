pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {QVImpactStreamStrategy} from "../../../contracts/strategies/_poc/qv-impact-stream/QVImpactStreamStrategy.sol";

// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// import Native
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

import {MockERC20} from "../../utils/MockERC20.sol";

/// @title QVImpactStreamStrategyTest
/// @notice Test suite for QVImpactStreamStrategy
/// @author allo-team
contract QVImpactStreamStrategyTest is Test, AlloSetup, RegistrySetupFull, StrategySetup, EventSetup, Errors, Native {
    event AllocatorAdded(address indexed allocator, address sender);
    event AllocatorRemoved(address indexed allocator, address sender);
    event Allocated(address indexed recipientId, uint256 votes, address allocator);
    event PayoutSet(QVImpactStreamStrategy.Payout[] payouts, address sender);

    QVImpactStreamStrategy strategyImplementation;
    QVImpactStreamStrategy strategy;

    bool public useRegistryAnchor;
    bool public metadataRequired;

    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint256 public maxVoiceCreditsPerAllocator;
    uint256 poolId;

    address allocator1 = address(0x1);
    address allocator2 = address(0x2);

    address[] allocators = [allocator1, allocator2];

    /// @notice Initialize the test suite
    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        useRegistryAnchor = true;
        metadataRequired = true;

        allocationStartTime = uint64(nextWeek());
        allocationEndTime = uint64(weekAfterNext());
        maxVoiceCreditsPerAllocator = 10;

        strategyImplementation = new QVImpactStreamStrategy(address(allo()), "QVImpactStreamStrategy");

        vm.deal(pool_admin(), 100 * 1e18);
        vm.startPrank(pool_admin());

        poolId = allo().createPoolWithCustomStrategy{value: 100 * 1e18}(
            poolProfile_id(),
            address(strategyImplementation),
            _createInitData(
                useRegistryAnchor, metadataRequired, allocationStartTime, allocationEndTime, maxVoiceCreditsPerAllocator
            ),
            NATIVE,
            100 * 1e18,
            _createMetadata("Pool-Metadata"),
            pool_managers()
        );

        strategy = QVImpactStreamStrategy(payable(address(allo().getStrategy(poolId))));
        strategy.batchAddAllocator(allocators);

        vm.stopPrank();
    }

    function test_deployment() public virtual {
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        assertEq(strategy.maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
    }

    function test_initialize() public virtual {
        QVImpactStreamStrategy newStrategy = new QVImpactStreamStrategy(address(allo()), "QVImpactStreamStrategy");

        vm.prank(address(allo()));
        newStrategy.initialize(
            poolId,
            _createInitData(
                useRegistryAnchor, metadataRequired, allocationStartTime, allocationEndTime, maxVoiceCreditsPerAllocator
            )
        );
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        assertEq(strategy.maxVoiceCreditsPerAllocator(), maxVoiceCreditsPerAllocator);
    }

    function test_initialize_Revert_ALREADY_INITIALIZED() public virtual {
        vm.prank(address(allo()));

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        strategy.initialize(
            poolId,
            _createInitData(
                useRegistryAnchor, metadataRequired, allocationStartTime, allocationEndTime, maxVoiceCreditsPerAllocator
            )
        );
    }

    function test_initialize_Revert_UNAUTHORIZED() public virtual {
        QVImpactStreamStrategy newStrategy = new QVImpactStreamStrategy(address(allo()), "QVImpactStreamStrategy");

        vm.expectRevert(UNAUTHORIZED.selector);
        newStrategy.initialize(
            poolId,
            _createInitData(
                useRegistryAnchor, metadataRequired, allocationStartTime, allocationEndTime, maxVoiceCreditsPerAllocator
            )
        );
    }

    function test_initialize_Revert_INVALID() public virtual {
        QVImpactStreamStrategy newStrategy = new QVImpactStreamStrategy(address(allo()), "QVImpactStreamStrategy");
        vm.startPrank(address(allo()));
        vm.warp(7 days);

        vm.expectRevert(INVALID.selector);
        newStrategy.initialize(
            poolId,
            _createInitData(
                useRegistryAnchor,
                metadataRequired,
                uint64(block.timestamp - 1 days),
                allocationEndTime,
                maxVoiceCreditsPerAllocator
            )
        );
        vm.expectRevert(INVALID.selector);
        newStrategy.initialize(
            poolId,
            _createInitData(
                useRegistryAnchor,
                metadataRequired,
                allocationStartTime,
                uint64(block.timestamp - 1 days),
                maxVoiceCreditsPerAllocator
            )
        );

        vm.stopPrank();
    }

    function test__registerRecipient() public virtual {
        vm.expectEmit(true, false, false, true);

        emit Registered(
            profile1_anchor(),
            _createRecipientData(profile1_anchor(), profile1_member1(), 1e18, _createMetadata("Recipient-Metadata")),
            pool_manager1()
        );

        __registerRecipient(1);
        assertEq(uint8(strategy.getRecipientStatus(profile1_anchor())), uint256(IStrategy.Status.Accepted));
        QVImpactStreamStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());
        assertEq(recipient.recipientAddress, profile1_member1());
        assertEq(recipient.requestedAmount, 1e18);
        assertEq(recipient.metadata.protocol, 1);
        assertEq(recipient.metadata.pointer, "Recipient-Metadata");
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_no_recipientAddress() public virtual {
        QVImpactStreamStrategy newStrategy = new QVImpactStreamStrategy(address(allo()), "QVImpactStreamStrategy");

        vm.deal(pool_manager1(), 100 * 1e18);
        vm.startPrank(pool_manager1());
        uint256 newPoolId = allo().createPoolWithCustomStrategy{value: 100 * 1e18}(
            poolProfile_id(),
            address(newStrategy),
            _createInitData(
                false, metadataRequired, allocationStartTime, allocationEndTime, maxVoiceCreditsPerAllocator
            ),
            NATIVE,
            0,
            _createMetadata("Pool-Metadata"),
            pool_managers()
        );

        vm.warp(allocationStartTime + 10);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, address(0)));
        allo().registerRecipient(
            newPoolId, _createRecipientData(address(0), address(0), 1e18, _createMetadata("Recipient-Metadata"))
        );

        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        Metadata memory metadata = Metadata({protocol: 0, pointer: ""});

        bytes memory data = abi.encode(profile1_anchor(), profile1_member1(), 1e18, metadata);

        vm.expectRevert(INVALID_METADATA.selector);
        vm.prank(pool_manager1());
        allo().registerRecipient(poolId, data);
    }

    function test__registerRecipient_Update() public virtual {
        vm.expectEmit(true, false, false, true);

        emit Registered(
            profile1_anchor(),
            _createRecipientData(profile1_anchor(), profile1_member1(), 1e18, _createMetadata("Recipient-Metadata")),
            pool_manager1()
        );

        __registerRecipient(1);

        emit UpdatedRegistration(
            profile1_anchor(),
            _createRecipientData(
                profile1_anchor(), profile1_member1(), 1e18, _createMetadata("Recipient-Metadata-Updated")
            ),
            pool_manager1()
        );

        vm.prank(pool_manager1());
        allo().registerRecipient(
            poolId,
            _createRecipientData(
                profile1_anchor(), profile1_member1(), 1e18, _createMetadata("Recipient-Metadata-Updated")
            )
        );

        QVImpactStreamStrategy.Recipient memory recipient = strategy.getRecipient(profile1_anchor());
        assertEq(recipient.metadata.pointer, "Recipient-Metadata-Updated");
    }

    function test_allocate() public {
        address recipient1 = __registerRecipient(1);
        address recipient2 = __registerRecipient(2);

        vm.warp(allocationStartTime + 1 days);

        vm.startPrank(allocator1);

        vm.expectEmit(true, false, false, true);
        emit Allocated(recipient1, 1e9, allocator1);

        allo().allocate(poolId, _createAllocateData(recipient1, 1));
        allo().allocate(poolId, _createAllocateData(recipient2, 4));

        assertEq(strategy.getRecipient(recipient1).totalVotesReceived, 1 * 1e9);
        assertEq(strategy.getRecipient(recipient2).totalVotesReceived, 2 * 1e9);

        assertEq(strategy.getVoiceCreditsCastByAllocator(allocator1), 5);
        assertEq(strategy.getVoiceCreditsCastByAllocatorToRecipient(allocator1, recipient1), 1);
        assertEq(strategy.getVoiceCreditsCastByAllocatorToRecipient(allocator1, recipient2), 4);
        assertEq(strategy.getVotesCastByAllocatorToRecipient(allocator1, recipient1), 1 * 1e9);
        assertEq(strategy.getVotesCastByAllocatorToRecipient(allocator1, recipient2), 2 * 1e9);

        allo().allocate(poolId, _createAllocateData(recipient1, 1));
        allo().allocate(poolId, _createAllocateData(recipient2, 4));

        assertEq(strategy.getRecipient(recipient1).totalVotesReceived, _sqrt(2 * 1e18));
        assertEq(strategy.getRecipient(recipient2).totalVotesReceived, _sqrt(8 * 1e18));

        assertEq(strategy.getVoiceCreditsCastByAllocator(allocator1), 10);
        assertEq(strategy.getVoiceCreditsCastByAllocatorToRecipient(allocator1, recipient1), 2);
        assertEq(strategy.getVoiceCreditsCastByAllocatorToRecipient(allocator1, recipient2), 8);
        assertEq(strategy.getVotesCastByAllocatorToRecipient(allocator1, recipient1), _sqrt(2 * 1e18));
        assertEq(strategy.getVotesCastByAllocatorToRecipient(allocator1, recipient2), _sqrt(8 * 1e18));

        vm.stopPrank();
    }

    function test_allocate_Revert_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.warp(allocationStartTime + 1 days);

        allo().allocate(poolId, _createAllocateData(profile1_anchor(), 1));
    }

    function test_allocate_Revert_INVALID_zero_voiceCredits() public {
        address recipient1 = __registerRecipient(1);

        vm.startPrank(allocator1);
        vm.warp(allocationStartTime + 1 days);

        vm.expectRevert(INVALID.selector);
        allo().allocate(poolId, _createAllocateData(recipient1, 0));
    }

    function test_allocate_Revert_RECIPIENT_ERROR_no_ProfileId() public {
        vm.prank(allocator1);
        vm.warp(allocationStartTime + 1 days);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, address(123)));
        allo().allocate(poolId, _createAllocateData(address(123), 1));
    }

    function test_allocate_Revert_INVALID_noVoiceCreditsLeft() public {
        address recipient1 = __registerRecipient(1);

        vm.startPrank(allocator1);
        vm.warp(allocationStartTime + 1 days);

        vm.expectRevert(INVALID.selector);
        allo().allocate(poolId, _createAllocateData(recipient1, 11));
    }

    function test_allocate_Revert_ALLOCATION_NOT_ACTIVE_before_allocation() public {
        address recipient1 = __registerRecipient(1);

        vm.startPrank(allocator1);
        vm.warp(allocationStartTime - 1 days);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        allo().allocate(poolId, _createAllocateData(recipient1, 1));
    }

    function test_allocate_Revert_ALLOCATION_NOT_ACTIVE_after_allocation() public {
        address recipient1 = __registerRecipient(1);

        vm.startPrank(allocator1);
        vm.warp(allocationEndTime + 1 days);

        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);
        allo().allocate(poolId, _createAllocateData(recipient1, 1));
    }

    function test_addAllocator() public {
        assertFalse(strategy.isValidAllocator(address(1234567)));
        vm.expectEmit(true, false, false, true);
        emit AllocatorAdded(address(1234567), pool_manager1());

        vm.prank(pool_manager1());
        strategy.addAllocator(address(1234567));
        assertTrue(strategy.isValidAllocator(address(1234567)));
    }

    function test_batchAddAllocator() public {
        assertFalse(strategy.isValidAllocator(address(1234567)));
        assertFalse(strategy.isValidAllocator(address(7654321)));

        vm.expectEmit(true, false, false, true);
        emit AllocatorAdded(address(1234567), pool_manager1());
        emit AllocatorAdded(address(7654321), pool_manager1());

        address[] memory allocatorsTmp = new address[](2);
        allocatorsTmp[0] = address(1234567);
        allocatorsTmp[1] = address(7654321);

        vm.prank(pool_manager1());
        strategy.batchAddAllocator(allocatorsTmp);

        assertTrue(strategy.isValidAllocator(address(1234567)));
        assertTrue(strategy.isValidAllocator(address(7654321)));
    }

    function test_addAllocator_Revert_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.addAllocator(address(1234567));
    }

    function test_batchAddAllocator_Revert_UNAUTHORIZED() public {
        address[] memory allocatorsTmp = new address[](2);
        allocatorsTmp[0] = address(1234567);
        allocatorsTmp[1] = address(7654321);

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.batchAddAllocator(allocatorsTmp);
    }

    function test_removeAllocator() public {
        assertTrue(strategy.isValidAllocator(allocator1));
        vm.expectEmit(true, false, false, true);
        emit AllocatorRemoved(allocator1, pool_manager1());

        vm.prank(pool_manager1());
        strategy.removeAllocator(allocator1);
        assertFalse(strategy.isValidAllocator(allocator1));
    }

    function test_batchRemoveAllocator() public {
        assertTrue(strategy.isValidAllocator(allocator1));
        assertTrue(strategy.isValidAllocator(allocator2));
        vm.expectEmit(true, false, false, true);
        emit AllocatorRemoved(allocator1, pool_manager1());
        emit AllocatorRemoved(allocator2, pool_manager1());

        address[] memory allocatorsTmp = new address[](2);
        allocatorsTmp[0] = allocator1;
        allocatorsTmp[1] = allocator2;

        vm.prank(pool_manager1());
        strategy.batchRemoveAllocator(allocatorsTmp);
        assertFalse(strategy.isValidAllocator(allocator1));
        assertFalse(strategy.isValidAllocator(allocator2));
    }

    function test_removeAllocator_Revert_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.removeAllocator(allocator1);
    }

    function test_batchRemoveAllocator_Revert_UNAUTHORIZED() public {
        address[] memory allocatorsTmp = new address[](2);
        allocatorsTmp[0] = allocator1;
        allocatorsTmp[1] = allocator2;

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.batchRemoveAllocator(allocatorsTmp);
    }

    function test_updateTimestamps() public {
        vm.startPrank(pool_manager1());
        vm.warp(allocationStartTime + 1 days);

        vm.expectEmit(true, false, false, true);
        emit TimestampsUpdated(allocationStartTime + 1 days, allocationEndTime + 1 days, pool_manager1());

        strategy.updatePoolTimestamps(allocationStartTime + 1 days, allocationEndTime + 1 days);

        assertEq(strategy.allocationStartTime(), allocationStartTime + 1 days);
        assertEq(strategy.allocationEndTime(), allocationEndTime + 1 days);
    }

    function test_Revert_updateTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.updatePoolTimestamps(allocationStartTime + 1 days, allocationEndTime + 1 days);
    }

    function test_Revert_updateTimestamps_INVALID() public {
        vm.startPrank(pool_manager1());
        vm.warp(allocationStartTime + 1 days);

        vm.expectRevert(INVALID.selector);
        strategy.updatePoolTimestamps(allocationStartTime, allocationEndTime);
    }

    function test_isPoolActive() public {
        vm.warp(allocationStartTime + 1 days);
        assertTrue(strategy.isPoolActive());
        vm.warp(allocationEndTime + 1 days);
        assertFalse(strategy.isPoolActive());
    }

    function test_setPayouts() public {
        __registerRecipient(1);
        __registerRecipient(2);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 50});

        vm.warp(allocationEndTime + 1 days);
        vm.expectEmit(true, false, false, true);
        emit PayoutSet(payouts, pool_manager1());

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);

        assertEq(strategy.payouts(profile1_anchor()), 50);
        assertEq(strategy.payouts(profile2_anchor()), 50);
    }

    function test_setPayouts_Revert_ALLOCATION_NOT_ENDED() public {
        __registerRecipient(1);
        __registerRecipient(2);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 50});

        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);
    }

    function test_Revert_setPayouts_INVALID_already_set() public {
        __registerRecipient(1);
        __registerRecipient(2);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 50});

        vm.warp(allocationEndTime + 1 days);

        vm.startPrank(pool_manager1());
        strategy.setPayouts(payouts);

        vm.expectRevert(INVALID.selector);
        strategy.setPayouts(payouts);

        vm.stopPrank();
    }

    function test_setPayouts_Revert_UNAUTHORIZED() public {
        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 50});

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.setPayouts(payouts);
    }

    function test_setPayouts_Revert_RECIPIENT_ERROR_zero_amount() public {
        __registerRecipient(1);
        __registerRecipient(2);

        vm.warp(allocationEndTime + 1 days);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 0});

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);
    }

    function test_setPayouts_Revert_RECIPIENT_ERROR_recipient_not_accepted() public {
        __registerRecipient(1);
        // __registerRecipient(2);

        vm.warp(allocationEndTime + 1 days);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 50});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 50});

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);
    }

    function test_setPayouts_Revert_INVALID_amount_exceeds_poolAmount() public {
        __registerRecipient(1);
        __registerRecipient(2);

        vm.warp(allocationEndTime + 1 days);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 100 * 1e18});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 100 * 1e18});

        vm.expectRevert(INVALID.selector);

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);
    }

    function test_getPayouts() public {
        __registerRecipients_setPayouts();

        address[] memory recipients = new address[](3);
        recipients[0] = profile1_anchor();
        recipients[1] = profile2_anchor();
        recipients[2] = address(0x123456789);

        IStrategy.PayoutSummary[] memory payoutSummaries = strategy.getPayouts(recipients, new bytes[](3));

        assertEq(payoutSummaries[0].recipientAddress, profile1_member1());
        assertEq(payoutSummaries[0].amount, 1e18);

        assertEq(payoutSummaries[1].recipientAddress, profile2_member1());
        assertEq(payoutSummaries[1].amount, 1e18);

        assertEq(payoutSummaries[2].recipientAddress, address(0));
        assertEq(payoutSummaries[2].amount, 0);
    }

    function test_distribute() public {
        __registerRecipients_setPayouts();

        vm.expectEmit(true, false, false, true);
        emit Distributed(profile1_anchor(), profile1_member1(), 1e18, pool_manager1());

        address[] memory recipients = new address[](2);
        recipients[0] = profile1_anchor();
        recipients[1] = profile2_anchor();

        uint256 recipient1AmountBefore = profile1_member1().balance;
        uint256 recipient2AmountBefore = profile2_member1().balance;

        vm.prank(pool_manager1());
        allo().distribute(poolId, recipients, "");

        assertEq(profile1_member1().balance, recipient1AmountBefore + 1e18);
        assertEq(profile2_member1().balance, recipient2AmountBefore + 1e18);
    }

    function test_distribute_Revert_RECIPIENT_ERROR_zeroAmount() public {
        __registerRecipients_setPayouts();

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

        address[] memory recipients = new address[](2);
        recipients[0] = profile1_anchor();
        recipients[1] = profile1_anchor();

        vm.prank(pool_manager1());
        allo().distribute(poolId, recipients, "");
    }

    function test_recoverFunds_native() public {
        vm.deal(address(strategy), 100 * 1e18);
        vm.startPrank(pool_manager1());

        strategy.recoverFunds(NATIVE, address(0x123456789));

        assertEq(address(strategy).balance, 0);
        assertEq(address(0x123456789).balance, 100 * 1e18);
    }

    function test_recoverFunds_ERC20() public {
        MockERC20 token = new MockERC20();
        token.mint(address(strategy), 100 * 1e18);
        vm.startPrank(pool_manager1());

        strategy.recoverFunds(address(token), address(0x123456789));

        assertEq(token.balanceOf(address(strategy)), 0);
        assertEq(token.balanceOf(address(0x123456789)), 100 * 1e18);
    }

    function test_Revert_recoverFunds_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.recoverFunds(NATIVE, address(0x123456789));
    }

    function _createMetadata(string memory _pointer) internal pure returns (Metadata memory) {
        return Metadata({protocol: 1, pointer: _pointer});
    }

    function _createInitData(
        bool _useRegistryAnchor,
        bool _metadataRequired,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        uint256 _maxVoiceCreditsPerAllocator
    ) internal pure returns (bytes memory) {
        return abi.encode(
            _useRegistryAnchor,
            _metadataRequired,
            _allocationStartTime,
            _allocationEndTime,
            _maxVoiceCreditsPerAllocator
        );
    }

    function _createRecipientData(
        address _recipientId,
        address _recipientAddress,
        uint256 _requestedAmount,
        Metadata memory _metadata
    ) internal pure returns (bytes memory) {
        return abi.encode(_recipientId, _recipientAddress, _requestedAmount, _metadata);
    }

    function _createAllocateData(address _recipientId, uint256 _amount) internal pure returns (bytes memory) {
        return abi.encode(_recipientId, _amount);
    }

    function __registerRecipient(uint256 _id) internal returns (address recipientId) {
        address recipientAddress;
        if (_id == 1) {
            recipientId = profile1_anchor();
            recipientAddress = profile1_member1();
        } else if (_id == 2) {
            recipientId = profile2_anchor();
            recipientAddress = profile2_member1();
        } else {
            revert();
        }

        vm.prank(pool_manager1());
        allo().registerRecipient(
            poolId, _createRecipientData(recipientId, recipientAddress, 1e18, _createMetadata("Recipient-Metadata"))
        );

        return recipientId;
    }

    function __registerRecipients_setPayouts() internal {
        __registerRecipient(1);
        __registerRecipient(2);

        QVImpactStreamStrategy.Payout[] memory payouts = new QVImpactStreamStrategy.Payout[](2);
        payouts[0] = QVImpactStreamStrategy.Payout({recipientId: profile1_anchor(), amount: 1e18});
        payouts[1] = QVImpactStreamStrategy.Payout({recipientId: profile2_anchor(), amount: 1e18});

        vm.warp(allocationEndTime + 1 days);

        vm.prank(pool_manager1());
        strategy.setPayouts(payouts);
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
