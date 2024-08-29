// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DirectAllocationStrategy} from "strategies/examples/direct-allocation/DirectAllocation.sol";
import {IntegrationBase} from "./IntegrationBase.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

contract IntegrationDirectAllocationStrategy is IntegrationBase {
    IAllo public allo;
    DirectAllocationStrategy public strategy;

    uint256 public poolId;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        strategy = new DirectAllocationStrategy(address(allo));

        // Deal
        deal(DAI, userAddr, 100000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);
        poolId = allo.createPoolWithCustomStrategy(
            profileId, address(strategy), abi.encode(), DAI, 0, Metadata({protocol: 0, pointer: ""}), managers
        );
    }

    function test_Revert_Register() public {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);

        vm.prank(address(allo));
        strategy.register(new address[](0), "", address(0));
    }

    function test_Revert_Distribute() public {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);

        vm.prank(address(allo));
        strategy.distribute(new address[](0), "", address(0));
    }

    function test_Allocate() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        recipients[2] = recipient2Addr;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;
        amounts[2] = 30 ether;

        address[] memory tokens = new address[](3);
        tokens[0] = DAI;
        tokens[1] = DAI;
        tokens[2] = DAI;

        vm.prank(userAddr);
        IERC20(DAI).approve(address(strategy), 100000 ether);

        vm.prank(address(allo));
        strategy.allocate(recipients, amounts, abi.encode(tokens), userAddr);

        assertEq(IERC20(DAI).balanceOf(recipient0Addr), 10 ether);
        assertEq(IERC20(DAI).balanceOf(recipient1Addr), 20 ether);
        assertEq(IERC20(DAI).balanceOf(recipient2Addr), 30 ether);
    }
}
