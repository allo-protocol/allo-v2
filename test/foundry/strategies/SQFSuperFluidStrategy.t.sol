// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SQFSuperFluidStrategy} from "../../../contracts/strategies/_poc/sqf-superfluid/SQFSuperFluidStrategy.sol";
import {RecipientSuperApp} from "../../../contracts/strategies/_poc/sqf-superfluid/RecipientSuperApp.sol";
import {RecipientSuperAppFactory} from "../../../contracts/strategies/_poc/sqf-superfluid/RecipientSuperAppFactory.sol";

import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

import {SuperTokenV1Library} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {SuperfluidGovernanceII} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/gov/SuperfluidGovernanceII.sol";
import {
    ISuperfluid,
    ISuperfluidPool,
    ISuperApp
} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperToken} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {GeneralDistributionAgreementV1} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/agreements/gdav1/GeneralDistributionAgreementV1.sol";
import {SuperfluidPool} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/agreements/gdav1/SuperfluidPool.sol";

import {MockPassportDecoder} from "test/utils/MockPassportDecoder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SQFSuperFluidStrategyTest is RegistrySetupFullLive, AlloSetup, Native, EventSetup, Errors {
    using SuperTokenV1Library for ISuperToken;

    event Reviewed(address indexed recipientId, IStrategy.Status status, address sender);
    event Canceled(address indexed recipientId, address sender);
    event MinPassportScoreUpdated(uint256 minPassportScore, address sender);
    event Distributed(address indexed sender, int96 flowRate);
    event TotalUnitsUpdated(address indexed recipientId, uint256 totalUnits);

    SQFSuperFluidStrategy _strategy;
    MockPassportDecoder _passportDecoder;

    uint256 poolId;

    bool useRegistryAnchor;
    bool metadataRequired;
    address passportDecoder;
    address superfluidHost;
    address allocationSuperToken;
    address recipientSuperAppFactory;
    uint64 registrationStartTime;
    uint64 registrationEndTime;
    uint64 allocationStartTime;
    uint64 allocationEndTime;
    uint256 minPassportScore;
    uint256 initialSuperAppBalance;

    address secondAllocator = makeAddr("second");

    ISuperToken superFakeDai = ISuperToken(0xaC7A5cf2E0A6DB31456572871Ee33eb6212014a9);
    IERC20 fakeDai = IERC20(0xd0DE1486F69495D49c02D8f541B7dADf9Cf5CD91);
    address superFakeDaiWhale = 0x301933aEf6bB308f090087e9075ed5bFcBd3e0B3;

    SuperfluidGovernanceII superfluidGov = SuperfluidGovernanceII(0x25382FdC6a862809EeFE918D065339cFA9227b9E);
    address superfluidOwner = 0xd15D5d0f5b1b56A4daEF75CfE108Cb825E97d015;

    function setUp() public {
        vm.createSelectFork({blockNumber: 18_562_300, urlOrAlias: "opgoerli"});
        __RegistrySetupFullLive();
        __AlloSetupLive();

        _passportDecoder = new MockPassportDecoder();
        _strategy = __deploy_strategy();

        // get some super fake dai
        vm.startPrank(superFakeDaiWhale);
        superFakeDai.transfer(address(this), 420 * 1e19);
        superFakeDai.transfer(address(_strategy), 420 * 1e16);
        superFakeDai.transfer(randomAddress(), 20 * 1e18);
        superFakeDai.transfer(secondAllocator, 20 * 1e18);

        fakeDai.transfer(address(this), 420 * 1e19);
        vm.stopPrank();

        useRegistryAnchor = true;
        metadataRequired = true;
        passportDecoder = address(_passportDecoder);
        superfluidHost = address(0xE40983C2476032A0915600b9472B3141aA5B5Ba9);
        allocationSuperToken = address(superFakeDai);
        registrationStartTime = uint64(block.timestamp);
        registrationEndTime = uint64(block.timestamp) + uint64(1 days);
        allocationStartTime = uint64(block.timestamp) + 120;
        allocationEndTime = uint64(block.timestamp) + uint64(2 days);
        minPassportScore = 69;
        initialSuperAppBalance = 420 * 1e8;
        recipientSuperAppFactory = address(new RecipientSuperAppFactory());

        // set empty app RegistrationKey
        vm.prank(superfluidOwner);
        superfluidGov.setAppRegistrationKey(
            ISuperfluid(superfluidHost), address(_strategy), "", block.timestamp + 60 days
        );

        poolId = __createPool(address(_strategy));

        _passportDecoder.setScore(address(this), 70);
        _passportDecoder.setScore(secondAllocator, 70);
    }

    function test_deployment() public {
        assertTrue(address(_strategy) != address(0));
        assertTrue(address(_strategy.getAllo()) == address(allo()));
        assertTrue(_strategy.getStrategyId() == keccak256(abi.encode("SQFSuperFluidStrategyv1")));
    }

    function test_initialize() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");

        uint256 poolId_ = __createPool(address(strategy_));

        assertEq(strategy_.getPoolId(), poolId_);
        assertEq(strategy_.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy_.metadataRequired(), metadataRequired);
        assertEq(address(strategy_.passportDecoder()), passportDecoder);
        assertEq(strategy_.superfluidHost(), superfluidHost);
        assertEq(address(strategy_.allocationSuperToken()), allocationSuperToken);
        assertEq(strategy_.registrationStartTime(), registrationStartTime);
        assertEq(strategy_.registrationEndTime(), registrationEndTime);
        assertEq(strategy_.allocationStartTime(), allocationStartTime);
        assertEq(strategy_.allocationEndTime(), allocationEndTime);
        assertEq(strategy_.minPassportScore(), minPassportScore);
        assertEq(strategy_.initialSuperAppBalance(), initialSuperAppBalance);
    }

    function testRevert_initialize_INVALID() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");
        initialSuperAppBalance = 0;

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy_),
            __encodeInitializeParams(),
            address(superFakeDai),
            0,
            Metadata(1, "test"),
            pool_managers()
        );
    }

    function testRevert_initialize_ZERO_ADDRESS() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");
        superfluidHost = address(0);

        vm.expectRevert(ZERO_ADDRESS.selector);
        vm.prank(pool_admin());
        allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy_),
            __encodeInitializeParams(),
            address(superFakeDai),
            0,
            Metadata(1, "test"),
            pool_managers()
        );
    }

    function test_registerRecipient() public {
        address recipientId = __register_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(recipient.recipientAddress, recipient1());
        assertEq(uint8(recipient.recipientStatus), uint8(1));
        assertTrue(recipient.useRegistryAnchor);
        assertEq(address(recipient.superApp), address(0));

        Metadata memory metadata = recipient.metadata;

        assertEq(metadata.protocol, 1);
        assertEq(metadata.pointer, "test");
    }

    function test_registerRecipient_not_usingRegistryAnchor() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");

        useRegistryAnchor = false;
        uint256 poolId_ = __createPool(address(strategy_));

        vm.prank(profile1_member1());
        allo().registerRecipient(poolId_, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));

        SQFSuperFluidStrategy.Recipient memory recipient = strategy_.getRecipient(profile1_anchor());

        assertEq(recipient.recipientAddress, recipient1());
        assertEq(uint8(recipient.recipientStatus), uint8(1));
        assertTrue(recipient.useRegistryAnchor);
        assertEq(address(recipient.superApp), address(0));

        Metadata memory metadata = recipient.metadata;

        assertEq(metadata.protocol, 1);
        assertEq(metadata.pointer, "test");
    }

    function test_registerRecipient_update() public {
        address recipientId = __register_recipient();

        vm.expectEmit(true, true, true, false);
        emit UpdatedRegistration(
            profile1_anchor(),
            abi.encode(profile1_anchor(), recipient1(), Metadata(1, "update-test")),
            profile1_member1()
        );

        vm.prank(profile1_member1());
        recipientId =
            allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "update-test")));

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        Metadata memory metadata = recipient.metadata;

        assertEq(metadata.pointer, "update-test");
    }

    function testRevert_registerRecipient_accepted_INVALID() public {
        __register_accept_recipient();

        vm.prank(profile1_member1());

        vm.expectRevert(INVALID.selector);
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
    }

    function testRevert_registerRecipient_rejected_INVALID() public {
        __register_reject_recipient();

        vm.prank(profile1_member1());

        vm.expectRevert(INVALID.selector);
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        vm.prank(profile1_member1());
        vm.expectRevert(INVALID_METADATA.selector);
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "")));
    }

    function testRevert_registerRecipient_RECIPIENT_ERROR_zero_recipientAddress() public {
        vm.prank(profile1_member1());
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), address(0), Metadata(1, "test")));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.prank(profile2_member1());

        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
    }

    function testRevert_registerRecipient_UNAUTHORIZED_not_usingRegistryAnchor() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");

        useRegistryAnchor = false;
        uint256 poolId_ = __createPool(address(strategy_));

        vm.prank(profile2_member1());

        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(poolId_, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
    }

    function test_reviewRecipient_Accept() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Accepted));
        assertTrue(address(recipient.superApp) != address(0));

        RecipientSuperApp superApp = RecipientSuperApp(recipient.superApp);

        assertEq(superApp.recipient(), recipient1());
        assertEq(address(superApp.strategy()), address(_strategy));
        assertEq(address(superApp.acceptedToken()), address(superFakeDai));

        assertEq(superFakeDai.balanceOf(address(superApp)), initialSuperAppBalance);
    }

    function test_reviewRecipient_Reject() public {
        address recipientId = __register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](1);
        statuses[0] = IStrategy.Status.Rejected;

        vm.prank(pool_manager1());
        vm.expectEmit(true, true, true, false);
        emit Reviewed(recipientId, IStrategy.Status.Rejected, pool_manager1());
        _strategy.reviewRecipients(recipients, statuses);

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Rejected));
        assertTrue(address(recipient.superApp) == address(0));
    }

    function testRevert_reviewRecipient_INVALID_array_mismatch() public {
        address recipientId = __register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](0);

        vm.prank(pool_manager1());

        vm.expectRevert(INVALID.selector);
        _strategy.reviewRecipients(recipients, statuses);
    }

    function testRevert_reviewRecipients_RECIPIENT_ERROR() public {
        address recipientId = __register_accept_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](1);
        statuses[0] = IStrategy.Status.Rejected;

        vm.prank(pool_manager1());
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));
        _strategy.reviewRecipients(recipients, statuses);
    }

    function test_cancelRecipient() public {
        address recipientId = __register_accept_recipient();

        vm.expectEmit(true, true, true, false);
        emit Canceled(recipientId, pool_manager1());

        vm.prank(pool_manager1());

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;
        _strategy.cancelRecipients(recipients);

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Canceled));
        assertTrue(address(recipient.superApp) == address(0));
        assertEq(_strategy.totalUnitsByRecipient(recipientId), 0);
        assertEq(_strategy.recipientFlowRate(recipientId), 0);
    }

    function testRevert_cancelRecipient_RECIPIENT_ERROR() public {
        __register_accept_recipient();
        vm.prank(pool_manager1());

        address[] memory recipients = new address[](1);
        recipients[0] = address(0);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipients[0]));
        _strategy.cancelRecipients(recipients);
    }

    function testRevert_adjustWeigthings_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        _strategy.adjustWeightings(0, 1);
    }

    function test_updatePoolTimestamps() public {
        uint64 newRegistrationStartTime = uint64(block.timestamp + 1 days);
        uint64 newRegistrationEndTime = uint64(block.timestamp + 2 days);
        uint64 newAllocationStartTime = uint64(block.timestamp + 3 days);
        uint64 newAllocationEndTime = uint64(block.timestamp + 4 days);

        vm.prank(pool_manager1());
        vm.expectEmit(true, true, true, false);
        emit TimestampsUpdated(
            newRegistrationStartTime,
            newRegistrationEndTime,
            newAllocationStartTime,
            newAllocationEndTime,
            pool_manager1()
        );

        _strategy.updatePoolTimestamps(
            newRegistrationStartTime, newRegistrationEndTime, newAllocationStartTime, newAllocationEndTime
        );

        assertEq(_strategy.registrationStartTime(), newRegistrationStartTime);
        assertEq(_strategy.registrationEndTime(), newRegistrationEndTime);
        assertEq(_strategy.allocationStartTime(), newAllocationStartTime);
        assertEq(_strategy.allocationEndTime(), newAllocationEndTime);
    }

    function testRevert_updatePoolTimestamps_INVALID() public {
        uint64 newRegistrationStartTime = uint64(block.timestamp + 1 days);
        uint64 newRegistrationEndTime = uint64(block.timestamp + 2 days);
        uint64 newAllocationStartTime = uint64(block.timestamp + 3 days);

        vm.prank(pool_manager1());
        vm.expectRevert(INVALID.selector);

        _strategy.updatePoolTimestamps(
            newRegistrationStartTime, newRegistrationEndTime, newAllocationStartTime, newRegistrationStartTime
        );
    }

    function test_getSuperApp() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(address(recipient.superApp), address(_strategy.getSuperApp(recipientId)));
        assertTrue(address(recipient.superApp) != address(0));
    }

    function test_getRecipient() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(recipient.recipientAddress, recipient1());
        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Accepted));
        assertTrue(recipient.useRegistryAnchor);
        assertEq(address(recipient.superApp), address(_strategy.getSuperApp(recipientId)));

        Metadata memory metadata = recipient.metadata;

        assertEq(metadata.protocol, 1);
        assertEq(metadata.pointer, "test");
    }

    function test_getRecipientStatus() public {
        address recipientId = __register_accept_recipient();

        assertEq(uint8(IStrategy.Status.Accepted), uint8(_strategy.getRecipientStatus(recipientId)));
    }

    function test_withdraw_ERC20() public {
        fakeDai.transfer(address(_strategy), 1e5);

        assertEq(fakeDai.balanceOf(address(_strategy)), 1e5);

        vm.prank(pool_manager1());
        _strategy.withdraw(address(fakeDai), 1e5);

        assertEq(fakeDai.balanceOf(address(_strategy)), 0);
    }

    function testRevert_withdraw_ERC20() public {
        fakeDai.transfer(address(_strategy), 1e5);

        assertEq(fakeDai.balanceOf(address(_strategy)), 1e5);

        vm.prank(randomAddress());

        vm.expectRevert(UNAUTHORIZED.selector);
        _strategy.withdraw(address(fakeDai), 1e5);
    }

    function testRevert_withdraw_pooltoken_INVALID() public {
        superFakeDai.transfer(address(_strategy), 1e5);

        vm.prank(pool_manager1());

        vm.expectRevert(INVALID.selector);
        _strategy.withdraw(address(superFakeDai), 1e5);
    }

    function test_closeStream() public {
        test_distribute();

        uint256 balanceBefore = superFakeDai.balanceOf(pool_manager1());
        vm.prank(pool_manager1());
        _strategy.closeStream();

        uint256 balanceAfter = superFakeDai.balanceOf(pool_manager1());

        assertTrue(balanceAfter > balanceBefore);
    }

    function test_allocate() public {
        address recipientId = __register_accept_recipient();

        vm.warp(uint256(allocationStartTime) + 1);

        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);
        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                380517503805 // 1 per month
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 8);
        assertEq(_strategy.recipientFlowRate(recipientId), 380517503805);
    }

    function test_allocate_second_time_same_user() public {
        test_allocate();
        address recipientId = profile1_anchor();

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                761035007610 // 2 per month
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 13);
        assertEq(_strategy.recipientFlowRate(recipientId), 761035007610);
    }

    function test_allocate_second_time_different_user() public {
        test_allocate();
        address recipientId = profile1_anchor();

        vm.startPrank(secondAllocator);
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                380517503805 // 1 per month
            )
        );

        vm.stopPrank();

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 22);
        assertEq(_strategy.recipientFlowRate(recipientId), 761035007610);
    }

    function test_allocate_multiple_recipients() public {
        (address recipientId1, address recipientId2) = __register_accept_recipients();

        vm.warp(uint256(registrationEndTime) + 1);

        vm.prank(pool_manager1());
        allo().distribute(poolId, new address[](0), abi.encode(1e10));

        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId1,
                761035007610 // 2 per month
            )
        );

        allo().allocate(
            poolId,
            abi.encode(
                recipientId2,
                1141552511415 // 3 per month
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId1), 14);
        assertEq(_strategy.recipientFlowRate(recipientId1), 761035007610);

        assertEq(_strategy.totalUnitsByRecipient(recipientId2), 19);
        assertEq(_strategy.recipientFlowRate(recipientId2), 1141552511415);

        vm.startPrank(secondAllocator);
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId1,
                380517503805 // 1 per month
            )
        );

        allo().allocate(
            poolId,
            abi.encode(
                recipientId2,
                761035007610 // 2 per month
            )
        );

        vm.stopPrank();

        assertEq(_strategy.totalUnitsByRecipient(recipientId1), 32);
        assertEq(_strategy.recipientFlowRate(recipientId1), 1141552511415);

        assertEq(_strategy.totalUnitsByRecipient(recipientId2), 50);
        assertEq(_strategy.recipientFlowRate(recipientId2), 1902587519025);

        SuperfluidPool gdaPool = SuperfluidPool(address(_strategy.gdaPool()));
        int96 netFlowGDA = superFakeDai.getNetFlowRate(address(gdaPool));
        uint128 totalUnits = gdaPool.getTotalUnits();

        assertTrue(uint96(netFlowGDA) > totalUnits);
    }

    function test_deleteFlow() public {
        test_allocate_second_time_different_user();

        vm.warp(block.timestamp + 100);

        address recipientId = profile1_anchor();
        address recipient = _strategy.getRecipient(recipientId).recipientAddress;
        address superApp = address(_strategy.getSuperApp(recipientId));

        superFakeDai.deleteFlow(address(this), superApp);

        int96 newNetFlowRate = superFakeDai.getCFANetFlowRate(superApp);
        int96 newFlowRateToRecipient = superFakeDai.getFlowRate(superApp, recipient);
        bool isSuperAppJailed = ISuperfluid(superfluidHost).isAppJailed(ISuperApp(superApp));

        assertEq(newNetFlowRate, 0);
        assertEq(newFlowRateToRecipient, 380517503805);
        assertEq(isSuperAppJailed, false);
        assertEq(_strategy.totalUnitsByRecipient(recipientId), 7);
    }

    function test_deleteFlow_multiple_times() public {
        test_allocate();

        vm.warp(block.timestamp + 100);

        address recipientId = profile1_anchor();
        address recipient = _strategy.getRecipient(recipientId).recipientAddress;
        address superApp = address(_strategy.getSuperApp(recipientId));

        superFakeDai.deleteFlow(address(this), superApp);

        vm.warp(block.timestamp + 100);

        int96 newNetFlowRate = superFakeDai.getCFANetFlowRate(superApp);
        int96 newFlowRateToRecipient = superFakeDai.getFlowRate(superApp, recipient);
        bool isSuperAppJailed = ISuperfluid(superfluidHost).isAppJailed(ISuperApp(superApp));

        assertEq(newNetFlowRate, 0);
        assertEq(newFlowRateToRecipient, 0);
        assertEq(isSuperAppJailed, false);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                380517503805 // 1 per month
            )
        );

        vm.warp(block.timestamp + 100);

        superFakeDai.deleteFlow(address(this), superApp);

        newNetFlowRate = superFakeDai.getCFANetFlowRate(superApp);
        newFlowRateToRecipient = superFakeDai.getFlowRate(superApp, recipient);
        isSuperAppJailed = ISuperfluid(superfluidHost).isAppJailed(ISuperApp(superApp));

        assertEq(newNetFlowRate, 0);
        assertEq(newFlowRateToRecipient, 0);
        assertEq(isSuperAppJailed, false);
        assertEq(_strategy.totalUnitsByRecipient(recipientId), 1);
    }

    function testRevert_allocate_UNATUTHORIZED() public {
        address recipientId = __register_accept_recipient();

        vm.warp(uint256(allocationStartTime) + 1);

        vm.startPrank(makeAddr("not-allowed"));
        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        vm.expectRevert(UNAUTHORIZED.selector);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                9 // super small flowRate
            )
        );

        vm.stopPrank();
    }

    function testRevert_allocate_RECIPIENT_ERROR() public {
        address recipientId = __register_recipient();

        vm.warp(uint256(allocationStartTime) + 1);

        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, recipientId));

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                0 // super small flowRate
            )
        );
    }

    function test_getPayout() public {
        address recipientId = __register_accept_recipient();
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        vm.warp(uint256(registrationEndTime) + 1);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                10 // super small flowRate
            )
        );

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        bytes[] memory data = new bytes[](1);
        data[0] = "";

        IStrategy.PayoutSummary[] memory payout = _strategy.getPayouts(recipients, data);

        assertEq(payout[0].recipientAddress, recipient1());
        assertEq(payout[0].amount, 10);
    }

    function test_distribute() public {
        __register_accept_recipient();
        vm.warp(uint256(registrationEndTime) + 1);

        vm.prank(pool_manager1());
        allo().distribute(poolId, new address[](0), abi.encode(1e10));

        GeneralDistributionAgreementV1 gdaPool = GeneralDistributionAgreementV1(address(_strategy.gdaPool()));
        int96 netFlowGDA = superFakeDai.getNetFlowRate(address(gdaPool));

        assertEq(netFlowGDA, 1e10);
    }

    function test_updateMinPassportScore() public {
        uint256 newMinPassportScore = 420;

        vm.expectEmit(true, true, true, false);
        emit MinPassportScoreUpdated(newMinPassportScore, pool_manager1());

        vm.prank(pool_manager1());
        _strategy.updateMinPassportScore(newMinPassportScore);

        assertEq(_strategy.minPassportScore(), newMinPassportScore);
    }

    function test_superAppEmergencyWithdraw() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        // Transfer DAI
        vm.prank(superFakeDaiWhale);
        superFakeDai.transfer(address(recipient.superApp), 2000);

        uint256 superAppBalanceBefore = superFakeDai.balanceOf(address(recipient.superApp));
        uint256 recipientBalanceBefore = superFakeDai.balanceOf(recipient.recipientAddress);

        vm.prank(recipient.recipientAddress);
        recipient.superApp.emergencyWithdraw(address(superFakeDai));

        uint256 superAppBalanceAfter = superFakeDai.balanceOf(address(recipient.superApp));
        uint256 recipientBalanceAfter = superFakeDai.balanceOf(recipient.recipientAddress);

        assertTrue(superAppBalanceAfter == 0);
        assertTrue(recipientBalanceAfter == recipientBalanceBefore + superAppBalanceBefore);
    }

    function test_superAppEmergencyWithdraw_unauthorized() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        vm.prank(pool_admin());
        vm.expectRevert(UNAUTHORIZED.selector);
        recipient.superApp.emergencyWithdraw(address(superFakeDai));
    }

    function test_superAppCloseStream() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        vm.warp(uint256(allocationStartTime) + 1);

        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);
        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                380517503805 // 1 per month
            )
        );

        assertEq(superFakeDai.getFlowRate(address(this), address(recipient.superApp)), 380517503805);

        vm.prank(recipient.recipientAddress);
        recipient.superApp.closeIncomingStream(address(this));

        assertEq(superFakeDai.getFlowRate(address(this), address(recipient.superApp)), 0);
    }

    function test_superAppCloseStream_unauthorized() public {
        address recipientId = __register_accept_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        vm.warp(uint256(allocationStartTime) + 1);

        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);
        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                380517503805 // 1 per month
            )
        );

        vm.prank(pool_admin());
        vm.expectRevert(UNAUTHORIZED.selector);
        recipient.superApp.closeIncomingStream(address(this));
    }

    function __deploy_strategy() internal returns (SQFSuperFluidStrategy) {
        return new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");
    }

    function __encodeInitializeParams() internal view returns (bytes memory) {
        return abi.encode(
            useRegistryAnchor,
            metadataRequired,
            passportDecoder,
            superfluidHost,
            allocationSuperToken,
            recipientSuperAppFactory,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime,
            minPassportScore,
            initialSuperAppBalance
        );
    }

    function __createPool(address strategy) internal returns (uint256 _poolId) {
        vm.prank(pool_admin());
        _poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            strategy,
            __encodeInitializeParams(),
            address(superFakeDai),
            0,
            Metadata(1, "test"),
            pool_managers()
        );
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.expectEmit(true, true, true, false);
        emit Registered(
            profile1_anchor(), abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")), profile1_member1()
        );

        vm.prank(profile1_member1());
        recipientId = allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](1);
        statuses[0] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        vm.expectEmit(true, true, true, false);
        emit Reviewed(recipientId, IStrategy.Status.Accepted, pool_manager1());
        _strategy.reviewRecipients(recipients, statuses);
    }

    function __register_accept_recipients() internal returns (address recipientId, address recipientId2) {
        recipientId = __register_recipient();
        vm.prank(profile2_member1());
        recipientId2 =
            allo().registerRecipient(poolId, abi.encode(profile2_anchor(), recipient2(), Metadata(1, "test")));

        address[] memory recipients = new address[](2);
        recipients[0] = recipientId;
        recipients[1] = recipientId2;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](2);
        statuses[0] = IStrategy.Status.Accepted;
        statuses[1] = IStrategy.Status.Accepted;

        vm.prank(pool_manager1());
        vm.expectEmit(true, true, true, false);
        emit Reviewed(recipientId, IStrategy.Status.Accepted, pool_manager1());
        _strategy.reviewRecipients(recipients, statuses);
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientId;

        IStrategy.Status[] memory statuses = new IStrategy.Status[](1);
        statuses[0] = IStrategy.Status.Rejected;

        vm.prank(pool_manager1());
        vm.expectEmit(true, true, true, false);
        emit Reviewed(recipientId, IStrategy.Status.Rejected, pool_manager1());
        _strategy.reviewRecipients(recipients, statuses);
    }
}
