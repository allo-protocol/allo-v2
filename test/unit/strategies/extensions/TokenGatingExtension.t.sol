// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// External Libraries
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Test libraries
import {MockGatingExtension} from "../../../mocks/MockGatingExtension.sol";
import {BaseGatingExtension} from "./BaseGatingExtension.sol";
import {TokenGatingExtension} from "strategies/extensions/gating/TokenGatingExtension.sol";

contract TokenGatingExtensionTest is BaseGatingExtension {
    function test_onlyWithERC20() public {
        /// mock balance of actor
        vm.mockCall(token, abi.encodeWithSelector(IERC20(token).balanceOf.selector, actor), abi.encode(1000));
        // actor has 1000 allo
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(token, 1000);
    }

    function testRevert_onlyWithERC20_tokenZeroAddress() public {
        address _token = address(0);
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_INVALID_TOKEN.selector);
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(_token, 1000);
    }

    function testRevert_onlyWithERC20_actorZeroAddress() public {
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_INVALID_ACTOR.selector);
        vm.prank(address(0));
        gatingExtension.onlyErc20Helper(token, 1000);
    }

    function testRevert_onlyWithERC20_insufficientBalance() public {
        vm.mockCall(token, abi.encodeWithSelector(IERC20(token).balanceOf.selector, actor), abi.encode(1000));
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_INSUFFICIENT_BALANCE.selector);
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(token, 1001);
    }
}
