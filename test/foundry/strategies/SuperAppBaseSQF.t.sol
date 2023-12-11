// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {SuperAppBaseSQF} from "../../../contracts/strategies/_poc/sqf-superfluid/SuperAppBaseSQF.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";
import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    SuperAppDefinitions
} from "@superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-contracts/apps/SuperTokenV1Library.sol";

contract SuperAppBaseSQFTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    using SuperTokenV1Library for ISuperToken;

    bytes32 public constant CFAV1_TYPE = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    ISuperfluid public HOST;

    bool activateOnCreated;
    bool activateOnUpdated;
    bool activateOnDeleted;
    string registrationKey;

    function setUp() public {
        // todo: setup
        vm.createSelectFork({blockNumber: 17_787_058, urlOrAlias: "mainnet"});

        // NOTE: this is mainnet HOST
        // reference: https://console.superfluid.finance/ethereum/protocol

        // HOST = ISuperfluid(0x4E583d9390082B65Bef884b629DFA426114CED6d);

        // uint256 callBackDefinitions =
        //     SuperAppDefinitions.APP_LEVEL_FINAL | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;

        // if (!activateOnCreated) {
        //     callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
        // }

        // if (!activateOnUpdated) {
        //     callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
        // }

        // if (!activateOnDeleted) {
        //     callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
        // }

        // HOST.registerAppWithKey(callBackDefinitions, registrationKey);
    }

    function test_deployment() public {}

    function test_initialize() public {}

    function testRevert_initialize_ALREADY_INITIALIZED() public {}

    function testRevert_initialize_UNAUTHORIZED() public {}

    function test_isAcceptedSuperToken() public {}

    function test_isAcceptedAgreement() public {}

    function test_onFlowUpdated() public {}

    function test_beforeAgreementCreated() public {}

    function test_afterAgreementCreated() public {}

    function test_afterAgreementTerminated() public {}
}
