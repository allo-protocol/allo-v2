// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SQFSuperFluidStrategy} from "../../../contracts/strategies/_poc/sqf-superfluid/SQFSuperFluidStrategy.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract SQFSuperFluidStrategyTest is RegistrySetupFullLive, AlloSetup, Native, EventSetup, Errors {
    SQFSuperFluidStrategy _strategy;

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

    address superFakeDai = 0xaC7A5cf2E0A6DB31456572871Ee33eb6212014a9;

    function setUp() public {
        vm.createSelectFork({blockNumber: 18_562_300, urlOrAlias: "opgoerli"});
        __RegistrySetupFullLive();
        __AlloSetupLive();

        _strategy = __deploy_strategy();

        useRegistryAnchor = true;
        metadataRequired = true;
        passportDecoder = address(1);
        superfluidHost = address(0xE40983C2476032A0915600b9472B3141aA5B5Ba9);
        allocationSuperToken = address(0xE01F8743677Da897F4e7De9073b57Bf034FC2433); // Super ETH
        registrationStartTime = uint64(block.timestamp) + 60;
        registrationEndTime = uint64(block.timestamp) + uint64(1 days);
        allocationStartTime = uint64(block.timestamp) + 120;
        allocationEndTime = uint64(block.timestamp) + uint64(2 days);
        minPassportScore = 69;
        initialSuperAppBalance = 420 * 1e5;
    }

    function test_deployment() public {
        assertTrue(address(_strategy) != address(0));
        assertTrue(address(_strategy.getAllo()) == address(allo()));
        assertTrue(_strategy.getStrategyId() == keccak256(abi.encode("SQFSuperFluidStrategyv1")));
    }

    function test_initialize() public {
        SQFSuperFluidStrategy strategy_ = new SQFSuperFluidStrategy(address(allo()), "SQFSuperFluidStrategyv1");

        uint256 poolId = __createPool(address(strategy_));

        assertEq(strategy_.getPoolId(), poolId);
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

    function __createPool(address strategy) internal returns (uint256 poolId) {
        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            strategy,
            __enocdeInitializeParams(),
            superFakeDai,
            0,
            Metadata(1, "test"),
            pool_managers()
        );
    }
}
