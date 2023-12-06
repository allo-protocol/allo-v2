// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {ISuperfluid, ISuperToken} from "@superfluid-finance/interfaces/superfluid/ISuperfluid.sol";
import {SuperfluidFrameworkDeployer} from "@superfluid-finance/utils/SuperfluidFrameworkDeployer.sol";

contract RecipientSuperAppTest is Test {
    error ZERO_ADDRESS();

    SuperfluidFrameworkDeployer.Framework sf;
    address public owner;

    function setUp() public {
        //DEPLOYING THE FRAMEWORK
        // SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
        // sf = sfDeployer.getFramework();

        // DEPLOYING DAI and DAI wrapper super token

        // vm.prank(owner);
        // ISuperToken daix = sfDeployer.deployWrapperToken("Fake DAI", "DAI", 18, 10000000000000);
    }

    function test_deploy() public {}

    function testRevert_deploy_ZERO_ADDRESS() public {}

    function test_onFlowUpdated() public {}
}
