pragma solidity 0.8.19;

import {ISablierV2LockupDynamic} from "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import {Broker, LockupDynamic} from "@sablier/v2-core/src/types/DataTypes.sol";
import {UD2x18} from "@sablier/v2-core/src/types/Math.sol";

import {LockupDynamicStrategy} from "../../../../contracts/strategies/sablier-v2/LockupDynamicStrategy.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

contract LockupDynamicStrategyTest is LockupBase_Test {
    event RecipientSegmentsChanged(address recipientId, LockupDynamic.SegmentWithDelta[] segments);

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
        strategy = new LockupDynamicStrategy(lockupDynamic, address(allo()),"LockupDynamicStrategy");
        poolId = __StrategySetup(address(strategy), setUpData);

        vm.label(address(lockupDynamic), "LockupDynamic");
        vm.label(address(strategy), "LockupDynamicStrategy");
    }

    struct Params {
        UD2x18 segmentExponent;
        uint128 fundPoolAmount;
        address recipientAddress;
    }

    /// Needed to prevent "Stack too deep" error
    struct Vars {
        uint128 segmentAmount;
        LockupDynamic.SegmentWithDelta[] segments;
        uint128 grantAmount;
        bool cancelable;
        bytes registerRecipientData;
        address[] recipientIds;
        LockupDynamicStrategy.Recipient recipient;
        bytes allocateData;
        LockupDynamic.Segment[] expectedSegments;
        uint256 streamId;
        uint256 recipientStreamId;
        uint256 afterDistributeNextStreamId;
        LockupDynamic.Stream stream;
        uint256 poolAmountBeforeCancel;
        uint256 allocatedGrantAmountBeforeCancel;
        uint256 refundedAmount;
    }

    function test_initialize() public {}

    function test_initialize_BaseStrategy_UNAUTHORIZED() public {}

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public {}

    function testRevert_initialize_INVALID() public {}

    function testForkFuzz_RegisterRecipientAllocateDistributeCancelStream(Params memory params) public {
        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        params.fundPoolAmount = uint128(_bound(params.fundPoolAmount, 1, type(uint96).max - 1));

        Vars memory vars;

        uint256 feeAmount = (params.fundPoolAmount * allo().getFeePercentage()) / allo().FEE_DENOMINATOR();
        vars.grantAmount = params.fundPoolAmount - uint128(feeAmount);

        vars.segments = new LockupDynamic.SegmentWithDelta[](2);
        vars.segments[0].delta = 1 days;
        vars.segments[1].delta = 12 weeks;
        vars.segments[0].amount = vars.grantAmount / 2;
        vars.segments[1].amount = vars.grantAmount - vars.segments[0].amount;
        vars.segments[0].exponent = params.segmentExponent;
        vars.segments[1].exponent = params.segmentExponent;

        deal({token: address(GTC), to: pool_manager1(), give: params.fundPoolAmount});
        GTC.approve(address(allo()), uint96(params.fundPoolAmount));

        vm.expectEmit({emitter: address(allo())});
        emit PoolFunded(poolId, vars.grantAmount, feeAmount);
        allo().fundPool(poolId, params.fundPoolAmount);

        vars.cancelable = true;
        vars.registerRecipientData = abi.encode(
            params.recipientAddress,
            useRegistryAnchor,
            vars.cancelable,
            vars.grantAmount,
            vars.segments,
            strategyMetadata
        );

        vars.recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), vars.registerRecipientData, pool_manager1());
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);

        strategy.setInternalRecipientStatusToInReview(vars.recipientIds);

        vars.recipient = strategy.getRecipient(vars.recipientIds[0]);
        assertEq(vars.recipient.cancelable, vars.cancelable, "recipient.cancelable");
        assertEq(vars.recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(vars.recipient.recipientStatus), 4, "recipient.recipientStatus"); // InReview
        assertEq(vars.recipient.grantAmount, vars.grantAmount, "recipient.vars.grantAmount");
        assertEq(vars.recipient.segments, vars.segments, "recipient.segments");

        vars.allocateData =
            abi.encode(vars.recipientIds[0], LockupDynamicStrategy.InternalRecipientStatus.Accepted, vars.grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(vars.recipientIds[0], vars.grantAmount, address(GTC), pool_manager1());
        allo().allocate(poolId, vars.allocateData);

        assertEq(uint8(strategy.getInternalRecipientStatus(vars.recipientIds[0])), 2, "after allocate internal status"); // Accepted

        vars.streamId = lockupDynamic.nextStreamId();

        vm.expectEmit({emitter: address(strategy)});
        emit Distributed(vars.recipientIds[0], params.recipientAddress, vars.grantAmount, pool_manager1());
        allo().distribute(poolId, vars.recipientIds, "");

        vars.recipientStreamId = strategy.getRecipientStreamId(vars.recipientIds[0], 0);
        assertEq(vars.recipientStreamId, vars.streamId, "recipientStreamId");

        vars.afterDistributeNextStreamId = lockupDynamic.nextStreamId();
        assertEq(vars.afterDistributeNextStreamId, vars.streamId + 1, "afterDistributeNextStreamId");

        vars.expectedSegments = new LockupDynamic.Segment[](2);
        vars.expectedSegments[0].milestone = uint40(block.timestamp) + vars.segments[0].delta;
        vars.expectedSegments[1].milestone = vars.expectedSegments[0].milestone + vars.segments[1].delta;
        vars.expectedSegments[0].amount = vars.segments[0].amount;
        vars.expectedSegments[1].amount = vars.segments[1].amount;
        vars.expectedSegments[0].exponent = params.segmentExponent;
        vars.expectedSegments[1].exponent = params.segmentExponent;

        vars.stream = lockupDynamic.getStream(vars.streamId);
        assertEq(vars.stream.sender, address(strategy), "stream.sender");
        assertEq(vars.stream.segments, vars.expectedSegments, "stream.segments");
        assertEq(vars.stream.isCancelable, vars.cancelable, "stream.isCancelable");
        assertEq(address(vars.stream.asset), address(GTC), "stream.asset");
        assertEq(vars.stream.amounts.deposited, vars.grantAmount, "stream.amounts.deposited");
        assertTrue(vars.stream.isStream, "stream.isStream");

        vm.warp(6 days);

        vars.poolAmountBeforeCancel = strategy.getPoolAmount();
        vars.allocatedGrantAmountBeforeCancel = strategy.getRecipient(vars.recipientIds[0]).grantAmount;
        vars.refundedAmount = lockupDynamic.refundableAmountOf(vars.streamId);
        strategy.cancelStream(vars.recipientIds[0], vars.streamId);
        assertEq(uint8(strategy.getInternalRecipientStatus(vars.recipientIds[0])), 5, "after cancel internal status"); // Canceled
        assertEq(
            strategy.getPoolAmount(),
            vars.poolAmountBeforeCancel + vars.refundedAmount,
            "pool amount after cancel stream"
        );
        assertEq(
            strategy.allocatedGrantAmount(),
            vars.allocatedGrantAmountBeforeCancel - vars.refundedAmount,
            "allocated grant amount after cancel stream"
        );
        assertEq(
            strategy.getRecipient(vars.recipientIds[0]).grantAmount,
            vars.grantAmount - vars.refundedAmount,
            "recipient grant amount after cancel stream"
        );
    }

    function test_ChangeRecipientDurations() public {
        address recipientAddress = makeAddr("recipientAddress");
        bool cancelable = true;
        uint256 grantAmount = 1000e18;
        LockupDynamic.SegmentWithDelta[] memory registerSegments = new LockupDynamic.SegmentWithDelta[](2);
        registerSegments[0].delta = 3 days;
        registerSegments[1].delta = 4 days;
        registerSegments[0].amount = 300e18;
        registerSegments[1].amount = 700e18;
        registerSegments[0].exponent = UD2x18.wrap(3.14e18);
        registerSegments[1].exponent = UD2x18.wrap(2.71e18);

        bytes memory registerRecipientData =
            abi.encode(recipientAddress, useRegistryAnchor, cancelable, grantAmount, registerSegments, strategyMetadata);

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        LockupDynamicStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.segments, registerSegments, "recipient.segments");

        LockupDynamic.SegmentWithDelta[] memory newSegments = new LockupDynamic.SegmentWithDelta[](2);
        newSegments[0].delta = 6 days;
        newSegments[1].delta = 12 days;
        newSegments[0].amount = 400e18;
        newSegments[1].amount = 600e18;
        newSegments[0].exponent = UD2x18.wrap(3.14e18);
        newSegments[1].exponent = UD2x18.wrap(2.71e18);

        vm.expectEmit({emitter: address(strategy)});
        emit RecipientSegmentsChanged(recipientIds[0], newSegments);
        strategy.changeRecipientSegments(recipientIds[0], newSegments);

        recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.segments, newSegments, "recipient.segments");
    }

    function test_SetBroker() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
    }

    /// ===============================
    /// ========== Helpers ============
    /// ===============================

    function assertEq(LockupDynamic.Segment[] memory a, LockupDynamic.Segment[] memory b, string memory message)
        internal
    {
        assertEq(keccak256(abi.encode(a)), keccak256(abi.encode(b)), message);
    }

    function assertEq(
        LockupDynamic.SegmentWithDelta[] memory a,
        LockupDynamic.SegmentWithDelta[] memory b,
        string memory message
    ) internal {
        assertEq(keccak256(abi.encode(a)), keccak256(abi.encode(b)), message);
    }
}
