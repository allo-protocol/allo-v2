// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EasyRPGF} from "strategies/examples/easy-rpgf/EasyRPGF.sol";
import {IntegrationBase} from "./IntegrationBase.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

contract IntegrationEasyRPGF is IntegrationBase {
    IAllo public allo;
    EasyRPGF public strategy;

    uint256 public poolId;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        strategy = new EasyRPGF(address(allo));

        // Deal
        deal(DAI, userAddr, 100000 ether);
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), 100000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);
        poolId = allo.createPoolWithCustomStrategy(
            profileId,
            address(strategy),
            abi.encode(),
            DAI,
            100000 ether,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );
    }

    function test_Revert_Allocate() public {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);
        vm.prank(address(allo));
        strategy.allocate(new address[](0), new uint256[](0), "", address(0));
    }

    function test_Distribute() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        recipients[2] = recipient2Addr;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;
        amounts[2] = 30 ether;

        vm.prank(address(allo));
        strategy.distribute(recipients, abi.encode(amounts), userAddr);

        assertEq(IERC20(DAI).balanceOf(recipient0Addr), 10 ether);
        assertEq(IERC20(DAI).balanceOf(recipient1Addr), 20 ether);
        assertEq(IERC20(DAI).balanceOf(recipient2Addr), 30 ether);
        assertEq(strategy.getPoolAmount(), 100000 ether - 60 ether);
    }
}
