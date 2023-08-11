pragma solidity 0.8.19;

// Interfaces
import {IStrategy} from "../../../../contracts/strategies/IStrategy.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "@sablier/v2-core/types/DataTypes.sol";

import {LockupLinearStrategy} from "../../../../contracts/strategies/sablier-v2/LockupLinearStrategy.sol";

import {LockupBase_Test} from "./LockupBase.t.sol";

import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

import {console2} from "forge-std/console2.sol";

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
            address(allo()),
            "LockupLinearStrategy"
        );
        poolId = __StrategySetup(address(strategy), setUpData);

        vm.label(address(lockupLinear), "LockupLinear");
        vm.label(address(strategy), "LockupLinearStrategy");
    }

    function test_initialize() public {
        strategy.setBroker(broker);
        assertEq(strategy.getBroker(), broker);
        assertEq(registryGating, strategy.registryGating());
        assertEq(metadataRequired, strategy.metadataRequired());
        assertEq(grantAmountRequired, strategy.grantAmountRequired());
    }

    function test_initialize_BaseStrategy_UNAUTHORIZED() public {}

    function testRevert_initialize_BaseStrategy_ALREADY_INITIALIZED() public {
        vm.expectRevert(IStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        vm.startPrank(address(allo()));
        strategy.initialize(poolId, setUpData);
    }

    function testRevert_initialize_INVALID() public {}

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

    function testForkFuzz_RegisterRecipientAllocateDistributeCancelStream(Params memory params) public {
        vm.assume(params.recipientAddress != address(0) && params.recipientAddress != pool_manager1());

        params.durations.total = uint40(_bound(params.durations.total, 1 days, 52 weeks));
        vm.assume(params.durations.cliff < params.durations.total);

        params.fundPoolAmount = _bound(params.fundPoolAmount, 1, type(uint96).max - 1);

        Vars memory vars;

        uint256 feeAmount = (params.fundPoolAmount * allo().getFeePercentage()) / allo().FEE_DENOMINATOR();
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

        strategy.setInternalRecipientStatusToInReview(vars.recipientIds);

        LockupLinearStrategy.Recipient memory recipient = strategy.getRecipient(vars.recipientIds[0]);
        assertEq(recipient.cancelable, vars.cancelable, "recipient.cancelable");
        assertEq(recipient.useRegistryAnchor, useRegistryAnchor, "recipient.useRegistryAnchor");
        assertEq(uint8(recipient.recipientStatus), 4, "recipient.recipientStatus"); // InReview
        assertEq(recipient.grantAmount, vars.grantAmount, "recipient.grantAmount");
        assertEq(recipient.durations.cliff, params.durations.cliff, "recipient.durations.cliff");
        assertEq(recipient.durations.total, params.durations.total, "recipient.durations.total");

        vars.allocateData =
            abi.encode(vars.recipientIds[0], LockupLinearStrategy.InternalRecipientStatus.Accepted, vars.grantAmount);

        vm.expectEmit({emitter: address(strategy)});
        emit Allocated(vars.recipientIds[0], vars.grantAmount, address(GTC), pool_manager1());
        allo().allocate(poolId, vars.allocateData);

        assertEq(uint8(strategy.getInternalRecipientStatus(vars.recipientIds[0])), 2, "after allocate internal status"); // Accepted

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

    function test_registerRecipient() public {
        Vars memory vars;

        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, vars.cancelable, vars.grantAmount, durations, strategyMetadata
        );

        vars.recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), vars.registerRecipientData, pool_manager1());
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);

        assertEq(vars.recipientIds[0], pool_manager1());
    }

    function testRevert_registerRecipient_UNAUTHORIZED_NOT_PROFILE_MEMBER() public {
        Vars memory vars;

        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.registerRecipientData = abi.encode(
            randomAddress(), useRegistryAnchor, vars.cancelable, vars.grantAmount, durations, strategyMetadata
        );
        vars.recipientIds = new address[](1);

        // FIXME:
        // vm.expectRevert(LockupLinearStrategy.UNAUTHORIZED.selector);
        // vm.startPrank(randomAddress());
        // vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);
        // vm.stopPrank();
    }

    // FIXME: grantAmountRequired needs to be set to true
    function testRevert_registerRecipient_INVALID_REGISTRATION() public {
        Vars memory vars;

        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.registerRecipientData =
            abi.encode(pool_manager1(), useRegistryAnchor, vars.cancelable, 0, durations, strategyMetadata);
        vars.recipientIds = new address[](1);
        grantAmountRequired = true;

        vm.expectRevert(LockupLinearStrategy.UNAUTHORIZED.selector);
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);
    }

    function testRevert_registerRecipient_RECIPIENT_ALREADY_ACCEPTED() public {
        Vars memory vars;

        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, vars.cancelable, vars.grantAmount, durations, strategyMetadata
        );
        vars.recipientIds = new address[](1);
        grantAmountRequired = true;

        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);
        vars.allocateData =
            abi.encode(vars.recipientIds[0], LockupLinearStrategy.InternalRecipientStatus.Accepted, vars.grantAmount);

        allo().allocate(poolId, vars.allocateData);

        vm.expectRevert(LockupLinearStrategy.RECIPIENT_ALREADY_ACCEPTED.selector);
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        Vars memory vars;

        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.registerRecipientData = abi.encode(
            pool_manager1(),
            useRegistryAnchor,
            vars.cancelable,
            vars.grantAmount,
            durations,
            Metadata({protocol: 0, pointer: ""})
        );
        vars.recipientIds = new address[](1);

        // FIXME: need to make metadata required to test this
        // vm.expectRevert(LockupLinearStrategy.INVALID_METADATA.selector);
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);
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
        recipientIds[0] = allo().registerRecipient(poolId, registerRecipientData);

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

    function testRevert_cancelStream_STATUS_NOT_ACCEPTED() public {}

    function test_getAllRecipientStreamIds() public {
        uint256[] memory streamIds = strategy.getAllRecipientStreamIds(recipient());

        assertEq(streamIds.length, 0);

        // TODO: add a recipient stream id or two
    }

    function test_GetPayouts() public {
        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipient();

        strategy.getPayouts(recipientIds, "");

        assertEq(strategy.getPayouts(recipientIds, "").length, 1);

        // TODO: add some data for payouts to not be 0
    }

    function test_getRecipientStatus() public {
        Vars memory vars;

        // get the status - should be None | 0
        assertEq(uint8(strategy.getRecipientStatus(recipient())), 0);

        // Register a new recipient
        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 3 days, total: 4 days});

        vars.cancelable = true;
        vars.grantAmount = 1e19;
        vars.registerRecipientData = abi.encode(
            pool_manager1(), useRegistryAnchor, vars.cancelable, vars.grantAmount, durations, strategyMetadata
        );
        vars.recipientIds = new address[](1);

        vm.expectEmit({emitter: address(strategy)});
        emit Registered(pool_manager1(), vars.registerRecipientData, pool_manager1());
        vars.recipientIds[0] = allo().registerRecipient(poolId, vars.registerRecipientData);

        assertEq(vars.recipientIds[0], pool_manager1());

        // Set the recipient status to InReview | 4
        strategy.setInternalRecipientStatusToInReview(vars.recipientIds);

        assertEq(uint8(strategy.getInternalRecipientStatus(vars.recipientIds[0])), 4); // InReview
    }

    function test_isValidAllocator() public {
        assertEq(strategy.isValidAllocator(pool_manager1()), true);
        assertEq(strategy.isValidAllocator(randomAddress()), false);
    }
}
