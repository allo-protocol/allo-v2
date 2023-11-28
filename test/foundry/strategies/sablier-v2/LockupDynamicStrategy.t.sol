pragma solidity ^0.8.19;

import {ISablierV2LockupDynamic} from "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import {Broker, LockupDynamic} from "@sablier/v2-core/src/types/DataTypes.sol";
import {UD2x18} from "@sablier/v2-core/src/types/Math.sol";

import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {LockupDynamicStrategy} from "../../../../contracts/strategies/_poc/sablier-v2/LockupDynamicStrategy.sol";
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

contract LockupDynamicStrategyTest is LockupBase_Test, Errors {
    event RecipientSegmentsChanged(address recipientId, LockupDynamic.SegmentWithDelta[] segments);

    ISablierV2LockupDynamic internal lockupDynamic = ISablierV2LockupDynamic(0x39EFdC3dbB57B2388CcC4bb40aC4CB1226Bc9E44);
    LockupDynamicStrategy internal strategy;
    uint256 internal poolId;

    bool internal registryGating = false;
    bool internal metadataRequired = true;
    bool internal grantAmountRequired = true;
    bytes internal setUpData = abi.encode(registryGating, metadataRequired, grantAmountRequired);

    function setUp() public override {
        LockupBase_Test.setUp();

        vm.startPrank(pool_manager1());
        strategy = new LockupDynamicStrategy(lockupDynamic, address(allo()), "LockupDynamicStrategy");
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

    function testForkFuzz_registerRecipient_allocate_distribute_cancelStream(Params memory params) public {
        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        params.fundPoolAmount = uint128(_bound(params.fundPoolAmount, 1, type(uint96).max - 1));

        Vars memory vars;

        uint256 feeAmount = (params.fundPoolAmount * allo().getPercentFee()) / allo().getFeeDenominator();
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

        strategy.setRecipientStatusToInReview(vars.recipientIds);

        vars.recipient = strategy.getRecipient(vars.recipientIds[0]);
        assertEq(vars.recipient.cancelable, vars.cancelable, "recipient.cancelable");
        assertEq(vars.recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(vars.recipient.recipientStatus), 5, "recipient.recipientStatus"); // InReview
        assertEq(vars.recipient.grantAmount, vars.grantAmount, "recipient.vars.grantAmount");
        assertEq(vars.recipient.segments, vars.segments, "recipient.segments");

        vars.allocateData = abi.encode(vars.recipientIds[0], IStrategy.Status.Accepted, vars.grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(vars.recipientIds[0], vars.grantAmount, address(GTC), pool_manager1());
        allo().allocate(poolId, vars.allocateData);

        assertEq(uint8(strategy.getRecipientStatus(vars.recipientIds[0])), 2, "after allocate status"); // Accepted

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
        assertEq(uint8(strategy.getRecipientStatus(vars.recipientIds[0])), 6, "after cancel status"); // Canceled
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

    function testRevert_cancelStream_STATUS_NOT_ACCEPTED() public {
        vm.expectRevert(LockupDynamicStrategy.STATUS_NOT_ACCEPTED.selector);
        strategy.cancelStream(recipient(), 0);
    }

    function testRevert_changeRecipientSegments_STATUS_NOT_PENDING_OR_INREVIEW() public {
        vm.expectRevert(LockupDynamicStrategy.STATUS_NOT_PENDING_OR_INREVIEW.selector);
        strategy.changeRecipientSegments(recipient(), registerSegments());
    }

    function test_changeRecipientSegments() public {
        address recipientAddress = makeAddr("recipientAddress");
        bool cancelable = true;
        uint256 grantAmount = 1000e18;
        LockupDynamic.SegmentWithDelta[] memory _registerSegments = new LockupDynamic.SegmentWithDelta[](2);
        _registerSegments[0].delta = 3 days;
        _registerSegments[1].delta = 4 days;
        _registerSegments[0].amount = 300e18;
        _registerSegments[1].amount = 700e18;
        _registerSegments[0].exponent = UD2x18.wrap(3.14e18);
        _registerSegments[1].exponent = UD2x18.wrap(2.71e18);

        bytes memory registerRecipientData = abi.encode(
            recipientAddress, useRegistryAnchor, cancelable, grantAmount, _registerSegments, strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        LockupDynamicStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.segments, _registerSegments, "recipient.segments");

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

    function test_setBroker() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
    }

    function test_initialize() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
        assertEq(registryGating, strategy.registryGating());
        assertEq(metadataRequired, strategy.metadataRequired());
        assertEq(grantAmountRequired, strategy.grantAmountRequired());
    }

    function test_initialize_UNAUTHORIZED() public {
        changePrank(randomAddress());
        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.initialize(poolId, setUpData);
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        strategy.initialize(poolId, setUpData);
    }

    function test_isPoolActiv() public {
        LockupDynamicStrategy _strategy =
            new LockupDynamicStrategy(lockupDynamic, address(allo()), "LockupDynamicStrategy");
        assertFalse(_strategy.isPoolActive());
        __StrategySetup(address(_strategy), setUpData);
        assertTrue(_strategy.isPoolActive());
    }

    function test_registerRecipient() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), registerRecipientData, pool_manager1());
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);
        assertEq(recipientIds[0], pool_manager1());
    }

    function testRevert_registerRecipient_UNAUTHORIZED_REGISTRY_GATING() public {
        bool _registryGating = true;
        LockupDynamicStrategy _strategy =
            new LockupDynamicStrategy(lockupDynamic, address(allo()), "LockupDynamicStrategy");
        bytes memory _setUpData = abi.encode(_registryGating, metadataRequired, grantAmountRequired);
        uint256 _poolId = __StrategySetup(address(_strategy), _setUpData);

        bool cancelable = true;
        uint256 grantAmount;
        bytes memory registerRecipientData =
            abi.encode(randomAddress(), randomAddress(), cancelable, grantAmount, registerSegments(), strategyMetadata);

        vm.startPrank(randomAddress());
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(_poolId, registerRecipientData);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_UNAUTHORIZED_NOT_PROFILE_MEMBER() public {
        bool _useRegistryAnchor = true;
        bool cancelable = true;
        uint256 grantAmount;
        bytes memory registerRecipientData = abi.encode(
            randomAddress(), _useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );

        vm.startPrank(randomAddress());
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(poolId, registerRecipientData);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_REGISTRATION() public {
        bool cancelable = true;
        bytes memory registerRecipientData =
            abi.encode(pool_manager1(), useRegistryAnchor, cancelable, 0, registerSegments(), strategyMetadata);

        vm.expectRevert(INVALID_REGISTRATION.selector);
        allo().registerRecipient(poolId, registerRecipientData);
    }

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        deal({token: address(GTC), to: pool_manager1(), give: grantAmount});
        GTC.approve(address(allo()), uint96(grantAmount));
        allo().fundPool(poolId, grantAmount);
        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Accepted, grantAmount - 1e18);
        allo().allocate(poolId, allocateData);

        vm.expectRevert(RECIPIENT_ALREADY_ACCEPTED.selector);
        allo().registerRecipient(poolId, registerRecipientData);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(),
            useRegistryAnchor,
            cancelable,
            grantAmount,
            registerSegments(),
            Metadata({protocol: 0, pointer: ""})
        );

        vm.expectRevert(INVALID_METADATA.selector);
        allo().registerRecipient(poolId, registerRecipientData);
    }

    function testRevert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        deal({token: address(GTC), to: pool_manager1(), give: grantAmount});
        GTC.approve(address(allo()), uint96(grantAmount));
        allo().fundPool(poolId, grantAmount);
        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Accepted, grantAmount);
        vm.expectRevert(LockupDynamicStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);
        allo().allocate(poolId, allocateData);
    }

    function test_allocate_Rejected() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Rejected, 0);
        allo().allocate(poolId, allocateData);

        assertEq(uint8(strategy.getRecipientStatus(recipientIds[0])), uint8(IStrategy.Status.Rejected));
    }

    function test_getAllRecipientStreamIds() public {
        address[] memory recipientIds = new address[](1);
        uint256[] memory streamIds = strategy.getAllRecipientStreamIds(recipientIds[0]);
        assertEq(streamIds.length, 0);

        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        deal({token: address(GTC), to: pool_manager1(), give: 2 * grantAmount});
        GTC.approve(address(allo()), uint96(2 * grantAmount));
        allo().fundPool(poolId, 2 * grantAmount);

        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Accepted, grantAmount);
        allo().allocate(poolId, allocateData);

        allo().distribute(poolId, recipientIds, "");
        streamIds = strategy.getAllRecipientStreamIds(recipientIds[0]);
        assertEq(streamIds.length, 1);
    }

    function test_getPayouts_ARRAY_MISMATCH() public {
        address[] memory recipientIds = new address[](1);
        bytes[] memory data = new bytes[](2);
        vm.expectRevert(ARRAY_MISMATCH.selector);
        strategy.getPayouts(recipientIds, data);
    }

    function test_GetPayouts() public {
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipient();
        assertEq(strategy.getPayouts(recipientIds, "").length, 1);
    }

    function test_getRecipientStatus() public {
        // get the status - should be None
        assertEq(uint8(strategy.getRecipientStatus(recipient())), 0); // None

        // Register a new recipient
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerSegments(), strategyMetadata
        );
        address[] memory recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), registerRecipientData, pool_manager1());
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        assertEq(recipientIds[0], pool_manager1());

        // Set the recipient status to InReview
        strategy.setRecipientStatusToInReview(recipientIds);
        assertEq(uint8(strategy.getRecipientStatus(recipientIds[0])), 1); // Pending
    }

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(pool_manager1()));
        assertFalse(strategy.isValidAllocator(randomAddress()));
    }

    function test_withdraw() public {
        uint256 amount = 100e18;
        deal({token: address(GTC), to: pool_manager1(), give: amount});
        GTC.approve(address(allo()), uint96(amount));
        allo().fundPool(poolId, amount);

        uint256 amountMinFee = amount - 1e18;
        assertEq(GTC.balanceOf(address(strategy)), amountMinFee);

        uint256 amountToWithdraw = 20e18;
        strategy.withdraw(amountToWithdraw);
        assertEq(GTC.balanceOf(address(strategy)), amountMinFee - amountToWithdraw);
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

    function registerSegments() internal pure returns (LockupDynamic.SegmentWithDelta[] memory) {
        LockupDynamic.SegmentWithDelta[] memory _registerSegments = new LockupDynamic.SegmentWithDelta[](1);
        _registerSegments[0].delta = 3 days;
        _registerSegments[0].amount = 100e18;
        _registerSegments[0].exponent = UD2x18.wrap(3.14e18);
        return _registerSegments;
    }
}
