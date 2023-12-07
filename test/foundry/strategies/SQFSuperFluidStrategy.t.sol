// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SuperAppBaseSQF} from "./SuperAppBaseSQF.t.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract SQFSuperFluidStrategyTest is RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    SuperAppBaseSQF _strategy;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));
    }

    function test_getRecipient() public {}

    function test_getRecipientStatus() public {}

    function testRevert_registerRecipient_INVALID_METADATA() public {}

    function testRevert_registerRecipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_UNAUTHORIZED_already_allocated() public {}

    function testRevert_registerRecipient_RECIPIENT_ERROR_zero_recipientAddress() public {}
}
