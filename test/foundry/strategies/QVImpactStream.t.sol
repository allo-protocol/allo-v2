// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {StdStorage, Test, stdStorage} from "forge-std/Test.sol";
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IRecipientsExtension} from "../../../contracts/extensions/interfaces/IRecipientsExtension.sol";
import {QVSimple} from "../../../contracts/strategies/QVSimple.sol";
import {QVImpactStream} from "../../../contracts/strategies/QVImpactStream.sol";

contract QVImpactStreamTest is Test {
    using stdStorage for StdStorage;

    event PayoutSet(QVImpactStream.Payout[] payouts, address sender);

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
            maxVoiceCreditsPerAllocator: 100
        });
        /// initialize
        vm.prank(mockAlloAddress);
        qvImpactStream.initialize(1, abi.encode(recipientInitData, qvInitData));

        /// create mock payouts array
        payouts.push(QVImpactStream.Payout({recipientId: recipient1, amount: 60}));
        payouts.push(QVImpactStream.Payout({recipientId: recipient2, amount: 40}));
    }

    function test_BatchAddAllocatorWhenCalledByPoolManager() external {
        vm.mockCall(
            mockAlloAddress, abi.encodeWithSelector(IAllo.isPoolManager.selector, 1, poolManager), abi.encode(true)
        );
        // it should call _addAllocator
        vm.skip(true);
    }

    function test_BatchRemoveAllocatorWhenCalledByPoolManager() external {
        vm.mockCall(
            mockAlloAddress, abi.encodeWithSelector(IAllo.isPoolManager.selector, 1, poolManager), abi.encode(true)
        );
        // it should call _removeAllocator
        vm.skip(true);
    }

    function test_SetPayoutsRevertWhen_PayoutSetIsTrue() external {
        stdstore.target(address(qvImpactStream)).sig("payoutSet()").checked_write(true);
        vm.expectRevert(QVImpactStream.PAYOUT_ALREADY_SET.selector);

        /// make it after allocation finished
        vm.warp(block.timestamp + allocationWindow + 1 days);
        vm.mockCall(
            mockAlloAddress, abi.encodeWithSelector(IAllo.isPoolManager.selector, 1, poolManager), abi.encode(true)
        );

        vm.prank(poolManager);
        qvImpactStream.setPayouts(payouts);
    }

    function test_SetPayoutsRevertWhen_PayoutAmountIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetPayoutsRevertWhen_RecipientStatusIsNotAccepted() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetPayoutsRevertWhen_TotalPayoutIsGreaterThanPoolAmount() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetPayoutsWhenCalledWithValidParameters() external {
        // it should set the payouts
        vm.skip(true);
    }

    function test_SetPayoutsWhenTotalPayoutIsLessThanPoolAmount() external {
        // it should emit event
        vm.skip(true);
    }

    function test__distributeRevertWhen_PayoutAmountForRecipientIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test__distributeWhenCalled() external {
        // it should remove the recipient from the payouts
        // it should transfer to the recipient
        // it should emit event
        vm.skip(true);
    }

    function test_GetTotalVotesForRecipientWhenCalled() external {
        // it should return the total votes for the recipient
        vm.skip(true);
    }

    function test_GetPayoutWhenCalled() external {
        // it should return the payout for the recipient
        vm.skip(true);
    }

    function test_RecoverFundsWhenTokenIsNative() external {
        // it should transfer the native balance to the recipient
        vm.skip(true);
    }

    function test_RecoverFundsWhenTokenIsNotNative() external {
        // it should transfer the token balance to the recipient
        vm.skip(true);
    }
}
