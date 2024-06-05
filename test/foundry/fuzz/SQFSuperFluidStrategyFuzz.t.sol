// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SQFSuperFluidStrategy} from "../../../contracts/strategies/_poc/sqf-superfluid/SQFSuperFluidStrategy.sol";
import {RecipientSuperApp} from "../../../contracts/strategies/_poc/sqf-superfluid/RecipientSuperApp.sol";
import {RecipientSuperAppFactory} from "../../../contracts/strategies/_poc/sqf-superfluid/RecipientSuperAppFactory.sol";

import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {console} from "forge-std/console.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

import {SuperTokenV1Library} from
    "../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
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

contract SQFSuperFluidStrategyTestFuzz is RegistrySetupFullLive, AlloSetup, Native, EventSetup, Errors {
    using SuperTokenV1Library for ISuperToken;
    using FixedPointMathLib for uint256;

    event Reviewed(address indexed recipientId, IStrategy.Status status, address sender);

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

    ISuperToken superFakeDai = ISuperToken(0xD6FAF98BeFA647403cc56bDB598690660D5257d2);
    IERC20 fakeDai = IERC20(0x4247bA6C3658Fa5C0F523BAcea8D0b97aF1a175e);
    address superFakeDaiWhale = 0x1a8b3554089d97Ad8656eb91F34225bf97055C68;

    function setUp() public {
        vm.createSelectFork({blockNumber: 11282376, urlOrAlias: "opsepolia"});
        __RegistrySetupFullLive();
        __AlloSetupLive();

        _passportDecoder = new MockPassportDecoder();
        _strategy = __deploy_strategy();

        // get some super fake dai
        vm.startPrank(superFakeDaiWhale);
        superFakeDai.transfer(address(this), 22003 * 1e18);
        superFakeDai.transfer(secondAllocator, 22003 * 1e18);
        superFakeDai.transfer(address(_strategy), 420 * 1e16);

        fakeDai.transfer(address(this), 420 * 1e19);
        vm.stopPrank();

        useRegistryAnchor = true;
        metadataRequired = true;
        passportDecoder = address(_passportDecoder);
        superfluidHost = address(0xd399e2Fb5f4cf3722a11F65b88FAB6B2B8621005);
        allocationSuperToken = address(superFakeDai);
        registrationStartTime = uint64(block.timestamp);
        registrationEndTime = uint64(block.timestamp) + uint64(1 days);
        allocationStartTime = uint64(block.timestamp) + 120;
        allocationEndTime = uint64(block.timestamp) + uint64(2 days);
        minPassportScore = 69;
        initialSuperAppBalance = 420 * 1e8;
        recipientSuperAppFactory = address(new RecipientSuperAppFactory());

        poolId = __createPool(address(_strategy));

        _passportDecoder.setScore(address(this), 70);
        _passportDecoder.setScore(secondAllocator, 70);
    }

    function testFuzz_allocate(uint256 flow) public {
        address recipientId = __register_accept_recipient();

        flow = bound(flow, 1, 396140812570000000);

        vm.warp(uint256(allocationStartTime) + 1);

        uint256 previousUnits = _strategy.totalUnitsByRecipient(recipientId);

        //unlimited allowance
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);
        allo().allocate(poolId, abi.encode(recipientId, flow));

        assertEq(___isSuperAppJailed(recipientId), false);
        uint256 scaledFlow = flow / 1e6;
        uint256 totalUnits =
            scaledFlow > 0 ? ((previousUnits * 1e5).sqrt() + scaledFlow.sqrt()) ** 2 : previousUnits * 1e5;
        assertEq(_strategy.totalUnitsByRecipient(recipientId), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        assertEq(_strategy.recipientFlowRate(recipientId), flow);
    }

    function testFuzz_allocate_second_time_same_user(uint256 flow, uint256 newFlow) public {
        newFlow = bound(newFlow, 1, 396140812570000000);
        flow = bound(flow, 1, 396140812570000000);

        testFuzz_allocate(flow);

        address recipientId = profile1_anchor();
        uint256 previousUnits = _strategy.totalUnitsByRecipient(recipientId);

        allo().allocate(poolId, abi.encode(recipientId, newFlow));

        assertEq(___isSuperAppJailed(recipientId), false);
        uint256 scaledFlow = newFlow / 1e6;
        uint256 scaledPreviousFlow = flow / 1e6;
        uint256 totalUnits = ((previousUnits * 1e5).sqrt() + scaledFlow.sqrt() - scaledPreviousFlow.sqrt()) ** 2;
        assertEq(_strategy.totalUnitsByRecipient(recipientId), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        assertEq(_strategy.recipientFlowRate(recipientId), newFlow);
    }

    function testFuzz_allocate_second_time_different_user(uint256 flow1, uint256 flow2) public {
        flow2 = bound(flow2, 1, 396140812570000000);
        flow1 = bound(flow1, 1, 396140812570000000);

        testFuzz_allocate(flow1);
        address recipientId = profile1_anchor();
        uint256 previousUnits = _strategy.totalUnitsByRecipient(recipientId);

        vm.startPrank(secondAllocator);
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(poolId, abi.encode(recipientId, flow2));

        vm.stopPrank();

        assertEq(_strategy.recipientFlowRate(recipientId), flow1 + flow2);
        uint256 scaledFlow = flow2 / 1e6;
        uint256 totalUnits =
            scaledFlow > 0 ? ((previousUnits * 1e5).sqrt() + scaledFlow.sqrt()) ** 2 : previousUnits * 1e5;
        assertEq(_strategy.totalUnitsByRecipient(recipientId), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        assertEq(___isSuperAppJailed(recipientId), false);
    }

    function testFuzz_allocate_multiple_recipients(uint256 flow1, uint256 flow2, uint256 newFlow1, uint256 newFlow2)
        public
    {
        flow1 = bound(flow1, 1, 396140812570000000);
        flow2 = bound(flow2, 1, 396140812570000000);
        newFlow1 = bound(newFlow1, 1, 396140812570000000);
        newFlow2 = bound(newFlow2, 1, 396140812570000000);

        (address recipientId1, address recipientId2) = __register_accept_recipients();
        uint256 previousUnits1 = _strategy.totalUnitsByRecipient(recipientId1);
        uint256 previousUnits2 = _strategy.totalUnitsByRecipient(recipientId2);

        vm.warp(uint256(registrationEndTime) + 1);

        vm.prank(pool_manager1());
        allo().distribute(poolId, new address[](0), abi.encode(1e10));

        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        allo().allocate(poolId, abi.encode(recipientId1, flow1));

        allo().allocate(poolId, abi.encode(recipientId2, newFlow1));

        uint256 scaledFlow = flow1 / 1e6;
        uint256 totalUnits =
            scaledFlow > 0 ? ((previousUnits1 * 1e5).sqrt() + scaledFlow.sqrt()) ** 2 : previousUnits1 * 1e5;
        assertEq(_strategy.totalUnitsByRecipient(recipientId1), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        scaledFlow = flow2 / 1e6;
        totalUnits = scaledFlow > 0 ? ((previousUnits2 * 1e5).sqrt() + scaledFlow.sqrt()) ** 2 : previousUnits2 * 1e5;
        assertEq(_strategy.totalUnitsByRecipient(recipientId1), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        assertEq(_strategy.recipientFlowRate(recipientId1), flow1);
        assertEq(_strategy.recipientFlowRate(recipientId2), newFlow1);

        vm.startPrank(secondAllocator);
        superFakeDai.increaseFlowRateAllowanceWithPermissions(address(_strategy), 7, type(int96).max);

        previousUnits1 = _strategy.totalUnitsByRecipient(recipientId1);
        previousUnits2 = _strategy.totalUnitsByRecipient(recipientId2);

        allo().allocate(poolId, abi.encode(recipientId1, flow2));

        allo().allocate(poolId, abi.encode(recipientId2, newFlow2));

        vm.stopPrank();

        uint256 scaledPreviousFlow = flow1 / 1e6;
        scaledFlow = flow2 / 1e6;
        totalUnits = ((previousUnits1 * 1e5).sqrt() + scaledFlow.sqrt() - scaledPreviousFlow.sqrt()) ** 2;
        assertEq(_strategy.totalUnitsByRecipient(recipientId1), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        scaledPreviousFlow = newFlow1 / 1e6;
        scaledFlow = newFlow2 / 1e6;
        totalUnits = ((previousUnits2 * 1e5).sqrt() + scaledFlow.sqrt() - scaledPreviousFlow.sqrt()) ** 2;
        assertEq(_strategy.totalUnitsByRecipient(recipientId2), totalUnits > 1e5 ? totalUnits / 1e5 : 1);
        assertEq(_strategy.recipientFlowRate(recipientId1), flow1 + flow2);
        assertEq(_strategy.recipientFlowRate(recipientId2), newFlow1 + newFlow2);

        SuperfluidPool gdaPool = SuperfluidPool(address(_strategy.gdaPool()));
        int96 netFlowGDA = superFakeDai.getNetFlowRate(address(gdaPool));
        uint128 totalComputedUnits = gdaPool.getTotalUnits();

        assertTrue(uint96(netFlowGDA) > totalComputedUnits);
        assertEq(___isSuperAppJailed(recipientId2), false);
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

    function ___isSuperAppJailed(address recipientId) internal view returns (bool isSuperAppJailed) {
        address superApp = address(_strategy.getSuperApp(recipientId));
        isSuperAppJailed = ISuperfluid(superfluidHost).isAppJailed(ISuperApp(superApp));
    }
}
