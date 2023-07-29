pragma solidity 0.8.19;

import {IERC20} from "@sablier/v2-core/types/Tokens.sol";
import {ISablierV2LockupDynamic} from "@sablier/v2-core/interfaces/ISablierV2LockupDynamic.sol";
import {Broker, LockupDynamic} from "@sablier/v2-core/types/DataTypes.sol";
import {UD2x18} from "@sablier/v2-core/types/Math.sol";

import {LockupDynamicStrategy} from "../../../../contracts/strategies/sablier-v2/LockupDynamicStrategy.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

contract LockupDynamicStrategyTest is LockupBase_Test {
    ISablierV2LockupDynamic internal lockupDynamic = ISablierV2LockupDynamic(0x39EFdC3dbB57B2388CcC4bb40aC4CB1226Bc9E44);
    LockupDynamicStrategy internal strategy;
    uint256 internal poolId;

    bool internal registryGating = false;
    bool internal metadataRequired = false;
    bool internal grantAmountRequired = false;
    bytes internal setUpData = abi.encode(registryGating, metadataRequired, grantAmountRequired);

    function setUp() public override {
        LockupBase_Test.setUp();

        vm.startPrank(pool_manager1());
        strategy = new LockupDynamicStrategy(lockupDynamic, address(allo),"LockupDynamicStrategy");
        poolId = __StrategySetup(address(strategy), setUpData);

        vm.label(address(lockupDynamic), "LockupDynamic");
        vm.label(address(strategy), "LockupDynamicStrategy");
    }

    struct Params {
        bool cancelable;
        uint40 startTime;
        UD2x18 segmentExponent;
        uint128 segmentAmount;
        address recipientAddress;
    }

    function testForkFuzz_RegisterRecipientAllocateDistribute(Params memory params) public {
        params.startTime = uint40(_bound(params.startTime, block.timestamp - 1 days, block.timestamp + 1 weeks));
        params.segmentAmount = uint128(_bound(params.segmentAmount, 1, type(uint96).max / 2 - 1));

        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](2);

        segments[0].milestone = params.startTime > block.timestamp ? params.startTime + 1 : uint40(block.timestamp + 1);
        segments[1].milestone = segments[0].milestone + 12 weeks;

        segments[0].amount = params.segmentAmount;
        segments[1].amount = params.segmentAmount;

        segments[0].exponent = params.segmentExponent;
        segments[1].exponent = params.segmentExponent;

        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        uint256 grantAmount = params.segmentAmount * 2;

        deal({token: address(GTC), to: pool_manager1(), give: grantAmount});
        GTC.approve(address(allo), uint96(grantAmount));
        allo.fundPool(poolId, grantAmount);

        bytes memory registerRecipientData = abi.encode(
            params.recipientAddress,
            useRegistryAnchor,
            params.cancelable,
            grantAmount,
            params.startTime,
            segments,
            strategyMetadata
        );

        address[] memory recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), registerRecipientData, pool_manager1());
        recipientIds[0] = allo.registerRecipient(poolId, registerRecipientData);

        strategy.setInternalRecipientStatusToInReview(recipientIds);

        LockupDynamicStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.cancelable, params.cancelable, "recipient.cancelable");
        assertEq(recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(recipient.recipientStatus), 4, "recipient.recipientStatus"); // InReview
        assertEq(recipient.grantAmount, grantAmount, "recipient.grantAmount");
        assertEq(recipient.segments, segments, "recipient.segments");

        bytes memory allocateData =
            abi.encode(recipientIds[0], LockupDynamicStrategy.InternalRecipientStatus.Accepted, grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(recipientIds[0], grantAmount, address(GTC), pool_manager1());
        allo.allocate(poolId, allocateData);

        assertEq(uint8(strategy.getInternalRecipientStatus(recipientIds[0])), 2, "after allocate internal status"); // Accepted

        uint256 streamId = lockupDynamic.nextStreamId();

        vm.expectEmit({emitter: address(strategy)});
        emit Distributed(recipientIds[0], params.recipientAddress, grantAmount, pool_manager1());
        allo.distribute(poolId, recipientIds, "");

        uint256 recipientStreamId = strategy.getRecipientStreamId(recipientIds[0], 0);
        assertEq(recipientStreamId, streamId, "recipientStreamIds");

        uint256 afterDistributeNextStreamId = lockupDynamic.nextStreamId();
        assertEq(afterDistributeNextStreamId, streamId + 1, "afterDistributeNextStreamId");

        LockupDynamic.Stream memory stream = lockupDynamic.getStream(streamId);
        assertEq(stream.sender, address(strategy), "stream.sender");
        assertEq(stream.segments, segments, "stream.segments");
        assertEq(stream.isCancelable, params.cancelable, "stream.isCancelable");
        assertEq(address(stream.asset), address(GTC), "stream.asset");
        assertEq(stream.amounts.deposited, grantAmount, "stream.amounts.deposited");
        assertTrue(stream.isStream, "stream.isStream");
    }

    /// ===============================
    /// ========== Helpers ============
    /// ===============================

    function assertEq(LockupDynamic.Segment[] memory a, LockupDynamic.Segment[] memory b, string memory message)
        internal
    {
        assertEq(keccak256(abi.encode(a)), keccak256(abi.encode(b)), message);
    }
}
