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

import {SuperfluidGovernanceII} from "@superfluid-contracts/gov/SuperfluidGovernanceII.sol";
import {ISuperfluid} from "@superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperToken} from "@superfluid-contracts/interfaces/superfluid/ISuperToken.sol";

import {MockPassportDecoder} from "test/utils/MockPassportDecoder.sol";

contract SQFSuperFluidStrategyTest is RegistrySetupFullLive, AlloSetup, Native, EventSetup, Errors {
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

    ISuperToken superFakeDai = ISuperToken(0xaC7A5cf2E0A6DB31456572871Ee33eb6212014a9);
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
        vm.prank(superFakeDaiWhale);
        superFakeDai.transfer(address(this), 420 * 1e19);
        superFakeDai.transfer(address(_strategy), 420 * 1e6);
        superFakeDai.transfer(randomAddress(), 420 * 1e19);

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

    function test_reviewRecipient_Approve() public {
        address recipientId = __register_approve_recipient();

        SQFSuperFluidStrategy.Recipient memory recipient = _strategy.getRecipient(recipientId);

        assertEq(uint8(recipient.recipientStatus), uint8(IStrategy.Status.Accepted));
        assertTrue(address(recipient.superApp) != address(0));

        RecipientSuperApp superApp = RecipientSuperApp(recipient.superApp);

        assertEq(superApp.recipient(), recipient1());
        assertEq(address(superApp.strategy()), address(_strategy));
        assertEq(address(superApp.acceptedToken()), address(superFakeDai));

        assertEq(superFakeDai.balanceOf(address(superApp)), initialSuperAppBalance);
    }

    function test_getRecipient() public {}

    function test_getRecipientStatus() public {}

    function testRevert_registerRecipient_INVALID_METADATA() public {}

    function testRevert_registerRecipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_UNAUTHORIZED_already_allocated() public {}

    function testRevert_registerRecipient_RECIPIENT_ERROR_zero_recipientAddress() public {}

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

    function __register_approve_recipient() internal returns (address recipientId) {
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
}
