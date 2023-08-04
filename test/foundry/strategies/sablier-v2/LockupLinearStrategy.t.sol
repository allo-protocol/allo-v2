pragma solidity 0.8.19;

import {ISablierV2LockupLinear} from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "@sablier/v2-core/types/DataTypes.sol";

import {LockupLinearStrategy} from "../../../../contracts/strategies/sablier-v2/LockupLinearStrategy.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

contract LockupLinearStrategyTest is LockupBase_Test {
    event RecipientDurationsChanged(address recipientId, LockupLinear.Durations durations);

    ISablierV2LockupLinear internal lockupLinear = ISablierV2LockupLinear(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);
    LockupLinearStrategy internal strategy;
    uint256 internal poolId;

    bool internal registryGating = false;
    bool internal metadataRequired = false;
    bool internal grantAmountRequired = false;
    bytes internal setUpData = abi.encode(registryGating, metadataRequired, grantAmountRequired);

    function setUp() public override {
        LockupBase_Test.setUp();

        vm.startPrank(pool_manager1());
        strategy = new LockupLinearStrategy(
            lockupLinear,
            address(allo),
            "LockupLinearStrategy"
        );
        poolId = __StrategySetup(address(strategy), setUpData);

        vm.label(address(lockupLinear), "LockupLinear");
        vm.label(address(strategy), "LockupLinearStrategy");
    }

    struct Params {
        LockupLinear.Durations durations;
        uint256 grantAmount;
        address recipientAddress;
    }

    function testForkFuzz_RegisterRecipientAllocateDistributeCancelStream(Params memory params) public {
        params.durations.total = uint40(_bound(params.durations.total, 1 days, 52 weeks));
        vm.assume(params.durations.cliff < params.durations.total);

        params.grantAmount = _bound(params.grantAmount, 1, type(uint96).max - 1);
        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        deal({token: address(GTC), to: pool_manager1(), give: params.grantAmount});
        GTC.approve(address(allo), uint96(params.grantAmount));
        allo.fundPool(poolId, params.grantAmount);

        bool cancelable = true;
        bytes memory registerRecipientData = abi.encode(
            params.recipientAddress,
            useRegistryAnchor,
            cancelable,
            params.grantAmount,
            params.durations,
            strategyMetadata
        );

        address[] memory recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), registerRecipientData, pool_manager1());
        recipientIds[0] = allo.registerRecipient(poolId, registerRecipientData);

        assertEq(recipientIds[0], pool_manager1());

        strategy.setInternalRecipientStatusToInReview(recipientIds);

        LockupLinearStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.cancelable, cancelable, "recipient.cancelable");
        assertEq(recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(recipient.recipientStatus), 4, "recipient.recipientStatus"); // InReview
        assertEq(recipient.grantAmount, params.grantAmount, "recipient.grantAmount");
        assertEq(recipient.durations.cliff, params.durations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, params.durations.total, "recipient.durations.total");

        bytes memory allocateData =
            abi.encode(recipientIds[0], LockupLinearStrategy.InternalRecipientStatus.Accepted, params.grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(recipientIds[0], params.grantAmount, address(GTC), pool_manager1());
        allo.allocate(poolId, allocateData);

        assertEq(uint8(strategy.getInternalRecipientStatus(recipientIds[0])), 2, "after allocate internal status"); // Accepted

        uint256 streamId = lockupLinear.nextStreamId();

        vm.expectEmit({emitter: address(strategy)});
        emit Distributed(recipientIds[0], params.recipientAddress, params.grantAmount, pool_manager1());
        allo.distribute(poolId, recipientIds, "");

        uint256 recipientStreamId = strategy.getRecipientStreamId(recipientIds[0], 0);
        assertEq(recipientStreamId, streamId, "recipientStreamIds");

        uint256 afterDistributeNextStreamId = lockupLinear.nextStreamId();
        assertEq(afterDistributeNextStreamId, streamId + 1, "afterDistributeNextStreamId");

        LockupLinear.Stream memory stream = lockupLinear.getStream(streamId);
        assertEq(stream.sender, address(strategy), "stream.sender");
        assertEq(stream.startTime, block.timestamp, "stream.startTime");
        assertEq(stream.cliffTime, block.timestamp + params.durations.cliff, "stream.cliffTime");
        assertEq(stream.endTime, block.timestamp + params.durations.total, "stream.endTime");
        assertEq(stream.isCancelable, cancelable, "stream.isCancelable");
        assertEq(address(stream.asset), address(GTC), "stream.asset");
        assertEq(stream.amounts.deposited, params.grantAmount, "stream.amounts.deposited");
        assertTrue(stream.isStream, "stream.isStream");

        vm.warp(lockupLinear.getEndTime(streamId) / 2);

        uint256 poolAmountBeforeCancel = strategy.getPoolAmount();
        uint256 allocatedGrantAmountBeforeCancel = strategy.allocatedGrantAmount();
        uint128 refundedAmount = lockupLinear.refundableAmountOf(streamId);
        strategy.cancelStream(recipientIds[0], streamId);
        assertEq(uint8(strategy.getInternalRecipientStatus(recipientIds[0])), 5, "after cancel internal status"); // Canceled
        assertEq(strategy.getPoolAmount(), poolAmountBeforeCancel + refundedAmount, "pool amount after cancel stream");
        assertEq(
            strategy.allocatedGrantAmount(),
            allocatedGrantAmountBeforeCancel - refundedAmount,
            "allocated grant amount after cancel stream"
        );
        assertEq(
            strategy.getRecipient(recipientIds[0]).grantAmount,
            params.grantAmount - refundedAmount,
            "recipient grant amount after cancel stream"
        );
    }

    function test_ChangeRecipientDurations() public {
        address recipientAddress = makeAddr("recipientAddress");
        bool cancelable = true;
        uint256 grantAmount = 1000e18;
        LockupLinear.Durations memory registerDurations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        bytes memory registerRecipientData = abi.encode(
            recipientAddress, useRegistryAnchor, cancelable, grantAmount, registerDurations, strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo.registerRecipient(poolId, registerRecipientData);

        LockupLinearStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.durations.cliff, registerDurations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, registerDurations.total, "recipient.durations.total");

        LockupLinear.Durations memory newDurations = LockupLinear.Durations({cliff: 6 days, total: 12 days});
        vm.expectEmit({emitter: address(strategy)});
        emit RecipientDurationsChanged(recipientIds[0], newDurations);
        strategy.changeRecipientDurations(recipientIds[0], newDurations);

        recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.durations.cliff, newDurations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, newDurations.total, "recipient.durations.total");
    }

    function test_SetBroker() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
    }
}
