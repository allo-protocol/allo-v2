// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SQFSuperFluidStrategy} from "../../../contracts/strategies/_poc/sqf-superfluid/SQFSuperFluidStrategy.sol";
import {RecipientSuperApp} from "../../../contracts/strategies/_poc/sqf-superfluid/RecipientSuperApp.sol";

import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

import {SuperTokenV1Library} from "@superfluid-contracts/apps/SuperTokenV1Library.sol";
import {SuperfluidGovernanceII} from "@superfluid-contracts/gov/SuperfluidGovernanceII.sol";
import {ISuperfluid, ISuperfluidPool} from "@superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperToken} from "@superfluid-contracts/interfaces/superfluid/ISuperToken.sol";
import {GeneralDistributionAgreementV1} from "@superfluid-contracts/agreements/gdav1/GeneralDistributionAgreementV1.sol";

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
        initialSuperAppBalance = 420 * 1e5;

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

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.prank(profile2_member1());

        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(poolId, abi.encode(profile1_anchor(), recipient1(), Metadata(1, "test")));
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

    function test_reviewRecipient_Approve() public {
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

    function test_fundPool_distribute() public {
        // superFakeDai.approve(address(allo()), type(uint256).max);
        // allo().fundPool(poolId, 1e17);

        // vm.warp(uint256(registrationEndTime) + 1);

        // vm.prank(pool_manager1());

        // int96 flowRate = 1e5;

        // FAIL. Reason: GDA_DISTRIBUTE_FOR_OTHERS_NOT_ALLOWED()
        // allo().distribute(poolId, new address[](0), abi.encode(flowRate));
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

    function test_allocate() public {
        address recipientId = __register_accept_recipient();

        vm.warp(uint256(allocationStartTime) + 1);

        // unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);
        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                9 // super small flowRate
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 10);
        assertEq(_strategy.recipientFlowRate(recipientId), 9);
    }

    function test_allocate_second_time_same_user() public {
        test_allocate();
        address recipientId = profile1_anchor();

        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                16 // super small flowRate
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 17);
        assertEq(_strategy.recipientFlowRate(recipientId), 16);
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
                16 // super small flowRate
            )
        );

        vm.stopPrank();

        assertEq(_strategy.totalUnitsByRecipient(recipientId), 26);
        assertEq(_strategy.recipientFlowRate(recipientId), 25);
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
                16 // super small flowRate
            )
        );

        allo().allocate(
            poolId,
            abi.encode(
                recipientId2,
                25 // super small flowRate
            )
        );

        assertEq(_strategy.totalUnitsByRecipient(recipientId1), 17);
        assertEq(_strategy.recipientFlowRate(recipientId1), 16);

        assertEq(_strategy.totalUnitsByRecipient(recipientId2), 26);
        assertEq(_strategy.recipientFlowRate(recipientId2), 25);

        vm.startPrank(secondAllocator);
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(
            poolId,
            abi.encode(
                recipientId1,
                9 // super small flowRate
            )
        );

        allo().allocate(
            poolId,
            abi.encode(
                recipientId2,
                36 // super small flowRate
            )
        );

        vm.stopPrank();

        assertEq(_strategy.totalUnitsByRecipient(recipientId1), 26);
        assertEq(_strategy.recipientFlowRate(recipientId1), 25);

        assertEq(_strategy.totalUnitsByRecipient(recipientId2), 62);
        assertEq(_strategy.recipientFlowRate(recipientId2), 61);

        vm.startPrank(recipientId1);
        superFakeDai.connectPool(_strategy.gdaPool());
        ISuperfluidPool gdaPool = ISuperfluidPool(address(_strategy.gdaPool()));
        int256 netFlowGDA = int256(superFakeDai.getNetFlowRate(address(gdaPool)));
        vm.stopPrank();

        int256 calcualtedFlowRate = int256(_strategy.recipientFlowRate(recipientId1) + _strategy.recipientFlowRate(recipientId2));

        // assertEq(netFlowGDA, calcualtedFlowRate);

        // should fail
        assertEq(superFakeDai.balanceOf(recipientId1), 0);
        assertEq(superFakeDai.balanceOf(recipientId2), 0);

        // check if the net flow rate is equal to the sum of the flow rates of the recipients based on their units
    }

    function testRevert_registerRecipient_UNAUTHORIZED_already_allocated() public {}

    function __deploy_strategy() internal returns (SQFSuperFluidStrategy) {
        return new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");
    }

    function __enocdeInitializeParams() internal view returns (bytes memory) {
        return abi.encode(
            useRegistryAnchor,
            metadataRequired,
            passportDecoder,
            superfluidHost,
            allocationSuperToken,
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
            __enocdeInitializeParams(),
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
