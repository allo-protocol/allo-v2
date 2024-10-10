// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {StdStorage, Test, stdStorage} from "forge-std/Test.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IBaseStrategy} from "strategies/IBaseStrategy.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {QVSimple} from "strategies/examples/quadratic-voting/QVSimple.sol";
import {QVImpactStream} from "strategies/examples/impact-stream/QVImpactStream.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract QVImpactStreamTest is Test {
    using stdStorage for StdStorage;

    event PayoutSet(QVImpactStream.Payout[] payouts, address sender);
    event AllocatorAdded(address indexed allocator, address sender);
    event AllocatorRemoved(address indexed allocator, address sender);
    event Distributed(address indexed _recipient, bytes _data);

    QVImpactStream qvImpactStream;

    address mockAlloAddress;
    address poolManager;
    address recipient1;
    address recipient2;

    uint256 allocationWindow;

    QVImpactStream.Payout[] payouts;

    function setUp() external {
        /// create a mock users
        mockAlloAddress = makeAddr("allo");
        poolManager = makeAddr("poolManager");
        recipient1 = makeAddr("recipient1");
        recipient2 = makeAddr("recipient2");

        allocationWindow = 7 days;

        /// deploy the strategy
        qvImpactStream = new QVImpactStream(mockAlloAddress);

        IRecipientsExtension.RecipientInitializeData memory recipientInitData = IRecipientsExtension
            .RecipientInitializeData({
            metadataRequired: false,
            registrationStartTime: uint64(block.timestamp),
            registrationEndTime: uint64(block.timestamp + allocationWindow)
        });

        QVSimple.QVSimpleInitializeData memory qvInitData = QVSimple.QVSimpleInitializeData({
            allocationStartTime: uint64(block.timestamp),
            allocationEndTime: uint64(block.timestamp + allocationWindow),
            maxVoiceCreditsPerAllocator: 100,
            isUsingAllocationMetadata: false
        });
        /// initialize
        vm.prank(mockAlloAddress);
        qvImpactStream.initialize(1, abi.encode(recipientInitData, qvInitData));

        /// create mock payouts array
        payouts.push(QVImpactStream.Payout({recipientId: recipient1, amount: 60}));
        payouts.push(QVImpactStream.Payout({recipientId: recipient2, amount: 40}));
    }

    modifier callWithPoolManager() {
        vm.mockCall(
            mockAlloAddress, abi.encodeWithSelector(IAllo.isPoolManager.selector, 1, poolManager), abi.encode(true)
        );
        _;
    }

    function test_SetPayoutsRevertWhen_PayoutSetIsTrue() external callWithPoolManager {
        stdstore.target(address(qvImpactStream)).sig("payoutSet()").checked_write(true);
        vm.expectRevert(QVImpactStream.QVImpactStream_PayoutAlreadySet.selector);

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);

        vm.prank(poolManager);
        qvImpactStream.setPayouts(payouts);
    }

    function test_SetPayoutsRevertWhen_PayoutAmountIsZero() external callWithPoolManager {
        vm.expectRevert(
            abi.encodeWithSelector(IRecipientsExtension.RecipientsExtension_RecipientError.selector, recipient1)
        );
        payouts.push(QVImpactStream.Payout({recipientId: recipient1, amount: 0}));

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);

        vm.prank(poolManager);
        qvImpactStream.setPayouts(payouts);
    }

    function test_SetPayoutsRevertWhen_RecipientStatusIsNotAccepted() external callWithPoolManager {
        vm.expectRevert(
            abi.encodeWithSelector(IRecipientsExtension.RecipientsExtension_RecipientError.selector, recipient1)
        );

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);

        /// since the recipient is not registered, his status should be NONE
        /// so setting payouts should fail
        vm.prank(poolManager);
        qvImpactStream.setPayouts(payouts);
    }

    function test_SetPayoutsRevertWhen_TotalPayoutIsGreaterThanPoolAmount() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetPayoutsWhenCalledWithValidParameters() external {
        // it should set the payouts
        vm.skip(true);
    }

    function test__distributeRevertWhen_PayoutAmountForRecipientIsZero() external callWithPoolManager {
        IAllo.Pool memory poolData = IAllo.Pool({
            profileId: keccak256(abi.encodePacked(recipient1)),
            strategy: IBaseStrategy(address(qvImpactStream)),
            token: address(0),
            metadata: Metadata({protocol: 0, pointer: ""}),
            managerRole: keccak256("MANAGER_ROLE"),
            adminRole: keccak256("ADMIN_ROLE")
        });
        vm.mockCall(mockAlloAddress, abi.encodeWithSelector(IAllo.getPool.selector, 1), abi.encode(poolData));

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);

        /// it should revert
        vm.expectRevert(
            abi.encodeWithSelector(IRecipientsExtension.RecipientsExtension_RecipientError.selector, recipient1)
        );

        address[] memory _recipients = new address[](1);
        _recipients[0] = recipient1;

        vm.prank(mockAlloAddress);
        qvImpactStream.distribute(_recipients, new bytes(0), poolManager);
    }

    function test__distributeWhenCalled() external callWithPoolManager {
        stdstore.target(address(qvImpactStream)).sig("payouts(address)").with_key(address(0)).checked_write(100);

        vm.prank(mockAlloAddress);
        qvImpactStream.increasePoolAmount(100);

        IAllo.Pool memory poolData = IAllo.Pool({
            profileId: keccak256(abi.encodePacked(recipient1)),
            strategy: IBaseStrategy(address(qvImpactStream)),
            token: address(0),
            metadata: Metadata({protocol: 0, pointer: ""}),
            managerRole: keccak256("MANAGER_ROLE"),
            adminRole: keccak256("ADMIN_ROLE")
        });
        vm.mockCall(mockAlloAddress, abi.encodeWithSelector(IAllo.getPool.selector, 1), abi.encode(poolData));

        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit Distributed(address(0), abi.encode(address(0), 100, poolManager));

        address[] memory _recipients = new address[](1);
        /// normally it would be recipient1 instead of address(0) but we cant mock the _recipients mapping
        _recipients[0] = address(0);

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);

        vm.prank(mockAlloAddress);
        qvImpactStream.distribute(_recipients, new bytes(0), poolManager);
    }

    function test_GetTotalVotesForRecipientWhenCalled() external {
        // it should return the total votes for the recipient
        vm.skip(true);
    }

    function test_GetPayoutWhenCalled() external {
        stdstore.target(address(qvImpactStream)).sig("payouts(address)").with_key(recipient1).checked_write(100);

        QVImpactStream.Payout memory payout = qvImpactStream.getPayout(recipient1);
        assertEq(payout.amount, 100);
        assertEq(payout.recipientId, recipient1);
    }
}
