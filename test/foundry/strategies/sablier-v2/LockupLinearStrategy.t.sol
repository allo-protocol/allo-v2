pragma solidity ^0.8.19;

import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {UD60x18} from "@sablier/v2-core/src/types/Math.sol";

import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {LockupLinearStrategy} from "../../../../contracts/strategies/_poc/sablier-v2/LockupLinearStrategy.sol";
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

contract LockupLinearStrategyTest is LockupBase_Test, Errors {
    event RecipientDurationsChanged(address recipientId, LockupLinear.Durations durations);

    ISablierV2LockupLinear internal lockupLinear = ISablierV2LockupLinear(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);
    LockupLinearStrategy internal strategy;
    uint256 internal poolId;

    bool internal registryGating = false;
    bool internal metadataRequired = true;
    bool internal grantAmountRequired = true;
    bytes internal setUpData = abi.encode(registryGating, metadataRequired, grantAmountRequired);

    function setUp() public override {
        LockupBase_Test.setUp();

        vm.startPrank(pool_manager1());
        strategy = new LockupLinearStrategy(lockupLinear, address(allo()), "LockupLinearStrategy");
        poolId = __StrategySetup(address(strategy), setUpData);

        vm.label(address(lockupLinear), "LockupLinear");
        vm.label(address(strategy), "LockupLinearStrategy");
    }

    struct Params {
        LockupLinear.Durations durations;
        uint256 fundPoolAmount;
        address recipientAddress;
    }

    /// Needed to prevent "Stack too deep" error
    struct Vars {
        uint256 grantAmount;
        bool cancelable;
        bytes registerRecipientData;
        address[] recipientIds;
        bytes allocateData;
        uint256 streamId;
        uint256 recipientStreamId;
        uint256 afterDistributeNextStreamId;
        uint256 poolAmountBeforeCancel;
        uint256 allocatedGrantAmountBeforeCancel;
        uint128 refundedAmount;
    }

    function testForkFuzz_registerRecipient_allocate_distribute_cancelStream(Params memory params) public {
        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        params.durations.total = uint40(_bound(params.durations.total, 1 days, 52 weeks));
        vm.assume(params.durations.cliff < params.durations.total);

        params.fundPoolAmount = _bound(params.fundPoolAmount, 1, type(uint96).max - 1);

        Vars memory vars;

        uint256 feeAmount = (params.fundPoolAmount * allo().getPercentFee()) / allo().getFeeDenominator();
        vars.grantAmount = params.fundPoolAmount - feeAmount;

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
            params.durations,
            strategyMetadata
        );

        vars.recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), vars.registerRecipientData, pool_manager1());
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);

        assertEq(vars.recipientIds[0], pool_manager1());

        strategy.setRecipientStatusToInReview(vars.recipientIds);

        LockupLinearStrategy.Recipient memory recipient = strategy.getRecipient(vars.recipientIds[0]);
        assertEq(recipient.cancelable, vars.cancelable, "recipient.cancelable");
        assertEq(recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(recipient.recipientStatus), 5, "recipient.recipientStatus"); // InReview
        assertEq(recipient.grantAmount, vars.grantAmount, "recipient.grantAmount");
        assertEq(recipient.durations.cliff, params.durations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, params.durations.total, "recipient.durations.total");

        vars.allocateData = abi.encode(vars.recipientIds[0], IStrategy.Status.Accepted, vars.grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(vars.recipientIds[0], vars.grantAmount, address(GTC), pool_manager1());
        allo().allocate(poolId, vars.allocateData);

        assertEq(uint8(strategy.getRecipientStatus(vars.recipientIds[0])), 2, "after allocate status"); // Accepted

        vars.streamId = lockupLinear.nextStreamId();

        vm.expectEmit({emitter: address(strategy)});
        emit Distributed(vars.recipientIds[0], params.recipientAddress, vars.grantAmount, pool_manager1());
        allo().distribute(poolId, vars.recipientIds, "");

        vars.recipientStreamId = strategy.getRecipientStreamId(vars.recipientIds[0], 0);
        assertEq(vars.recipientStreamId, vars.streamId, "recipientStreamIds");

        vars.afterDistributeNextStreamId = lockupLinear.nextStreamId();
        assertEq(vars.afterDistributeNextStreamId, vars.streamId + 1, "afterDistributeNextStreamId");

        LockupLinear.Stream memory stream = lockupLinear.getStream(vars.streamId);
        assertEq(stream.sender, address(strategy), "stream.sender");
        assertEq(stream.startTime, block.timestamp, "stream.startTime");
        assertEq(stream.cliffTime, block.timestamp + params.durations.cliff, "stream.cliffTime");
        assertEq(stream.endTime, block.timestamp + params.durations.total, "stream.endTime");
        assertEq(stream.isCancelable, vars.cancelable, "stream.isCancelable");
        assertEq(address(stream.asset), address(GTC), "stream.asset");
        assertEq(stream.amounts.deposited, vars.grantAmount, "stream.amounts.deposited");
        assertTrue(stream.isStream, "stream.isStream");

        vm.warp(lockupLinear.getEndTime(vars.streamId) / 2);

        vars.poolAmountBeforeCancel = strategy.getPoolAmount();
        vars.allocatedGrantAmountBeforeCancel = strategy.allocatedGrantAmount();
        vars.refundedAmount = lockupLinear.refundableAmountOf(vars.streamId);
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
        vm.expectRevert(LockupLinearStrategy.STATUS_NOT_ACCEPTED.selector);
        strategy.cancelStream(recipient(), 0);
    }

    function testRevert_changeRecipientDurations_STATUS_NOT_PENDING_OR_INREVIEW() public {
        vm.expectRevert(LockupLinearStrategy.STATUS_NOT_PENDING_OR_INREVIEW.selector);
        strategy.changeRecipientDurations(recipient(), LockupLinear.Durations({cliff: 0, total: 0}));
    }

    function test_changeRecipientDurations() public {
        address recipientAddress = makeAddr("recipientAddress");
        bool cancelable = true;
        uint256 grantAmount = 1000e18;
        LockupLinear.Durations memory _registerDurations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        bytes memory registerRecipientData = abi.encode(
            recipientAddress, useRegistryAnchor, cancelable, grantAmount, _registerDurations, strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        LockupLinearStrategy.Recipient memory recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.durations.cliff, _registerDurations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, _registerDurations.total, "recipient.durations.total");

        LockupLinear.Durations memory newDurations = LockupLinear.Durations({cliff: 6 days, total: 12 days});
        vm.expectEmit({emitter: address(strategy)});
        emit RecipientDurationsChanged(recipientIds[0], newDurations);
        strategy.changeRecipientDurations(recipientIds[0], newDurations);

        recipient = strategy.getRecipient(recipientIds[0]);
        assertEq(recipient.durations.cliff, newDurations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, newDurations.total, "recipient.durations.total");
    }

    function test_setBroker() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
    }

    function test_getBroker() public {
        assertEq(strategy.getBroker(), Broker({account: address(0), fee: UD60x18.wrap(0)}));
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
        LockupLinearStrategy _strategy = new LockupLinearStrategy(lockupLinear, address(allo()), "LockupLinearStrategy");
        assertFalse(_strategy.isPoolActive());
        __StrategySetup(address(_strategy), setUpData);
        assertTrue(_strategy.isPoolActive());
    }

    function test_registerRecipient() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), registerRecipientData, pool_manager1());
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);
        assertEq(recipientIds[0], pool_manager1());
    }

    function testRevert_registerRecipient_UNAUTHORIZED_REGISTRY_GATING() public {
        bool _registryGating = true;
        LockupLinearStrategy _strategy = new LockupLinearStrategy(lockupLinear, address(allo()), "LockupLinearStrategy");
        bytes memory _setUpData = abi.encode(_registryGating, metadataRequired, grantAmountRequired);
        uint256 _poolId = __StrategySetup(address(_strategy), _setUpData);

        bool cancelable = true;
        uint256 grantAmount;
        bytes memory registerRecipientData =
            abi.encode(randomAddress(), randomAddress(), cancelable, grantAmount, registerDurations(), strategyMetadata);

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
            randomAddress(), _useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
        );

        vm.startPrank(randomAddress());
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(poolId, registerRecipientData);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_REGISTRATION() public {
        bool cancelable = true;
        bytes memory registerRecipientData =
            abi.encode(pool_manager1(), useRegistryAnchor, cancelable, 0, registerDurations(), strategyMetadata);

        vm.expectRevert(INVALID_REGISTRATION.selector);
        allo().registerRecipient(poolId, registerRecipientData);
    }

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
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
            registerDurations(),
            Metadata({protocol: 0, pointer: ""})
        );

        vm.expectRevert(INVALID_METADATA.selector);
        allo().registerRecipient(poolId, registerRecipientData);
    }

    function testRevert_allocate_ALLOCATION_EXCEEDS_POOL_AMOUNT() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        deal({token: address(GTC), to: pool_manager1(), give: grantAmount});
        GTC.approve(address(allo()), uint96(grantAmount));
        allo().fundPool(poolId, grantAmount);
        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Accepted, grantAmount);
        vm.expectRevert(LockupLinearStrategy.ALLOCATION_EXCEEDS_POOL_AMOUNT.selector);
        allo().allocate(poolId, allocateData);
    }

    function test_allocate_Rejected() public {
        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
        );

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

        bytes memory allocateData = abi.encode(recipientIds[0], IStrategy.Status.Rejected, 0);
        allo().allocate(poolId, allocateData);

        assertEq(uint8(strategy.getRecipientStatus(recipientIds[0])), 3); // Rejected
    }

    function test_getAllRecipientStreamIds() public {
        address[] memory recipientIds = new address[](1);
        uint256[] memory streamIds = strategy.getAllRecipientStreamIds(recipientIds[0]);
        assertEq(streamIds.length, 0);

        bool cancelable = true;
        uint256 grantAmount = 100e18;
        bytes memory registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
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
            pool_manager1(), useRegistryAnchor, cancelable, grantAmount, registerDurations(), strategyMetadata
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

    function registerDurations() internal pure returns (LockupLinear.Durations memory) {
        LockupLinear.Durations memory _durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});
        return _durations;
    }
}
