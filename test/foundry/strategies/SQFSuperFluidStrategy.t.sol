// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {SuperAppBaseSQF} from "./SuperAppBaseSQF.t.sol";

contract SQFSuperFluidStrategyTest {
    SuperAppBaseSQF _strategy;

    function setUp() public {}

    function test_getRecipient() public {}

    function test_getRecipientStatus() public {}

    function testRevert_registerRecipient_INVALID_METADATA() public {}

    function testRevert_registerRecipient_UNAUTHORIZED() public {}

    function testRevert_registerRecipient_UNAUTHORIZED_already_allocated() public {}

    function testRevert_registerRecipient_RECIPIENT_ERROR_zero_recipientAddress() public {}
}
