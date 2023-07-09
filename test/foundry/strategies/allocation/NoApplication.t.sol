// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Allo} from "../../../../contracts/core/Allo.sol";
import {TestUtilities} from "../../utils/TestUtilities.sol";
import "../../../../contracts/interfaces/IAllocationStrategy.sol";
import "../../../../contracts/interfaces/IDistributionStrategy.sol";

import {MockAllocation} from "../../utils/MockAllocation.sol";
import {MockDistribution} from "../../utils/MockDistribution.sol";
import {MockToken} from "../../utils/MockToken.sol";

contract NoApplicationTest is Test {
    function setUp() public {}

    function test_initialize() public {}

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {}

    function testRevert_registerRecipient_NOT_IMPLEMENTED() public {}

    function testRevert_getApplicationStatus_NOT_IMPLEMENTED() public {}

    function test_getPayout() public {}

    function test_allocate() public {}

    function testRevert_allocate_NOT_ELIGIBLE() public {}

    function test_readyToPayout() public {}

    function test_isEligibleForAllocation() public {}
}
