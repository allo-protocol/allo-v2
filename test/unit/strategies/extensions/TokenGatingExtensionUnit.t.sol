// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockTokenGatingExtension} from "test/smock/MockMockTokenGatingExtension.sol";
import {TokenGatingExtension} from "contracts/strategies/extensions/gating/TokenGatingExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenGatingExtensionUnit is Test {
    MockMockTokenGatingExtension tokenGatingExtension;

    function setUp() external {
        tokenGatingExtension = new MockMockTokenGatingExtension(address(0), "MockTokenGatingExtension");
    }

    function test_RevertWhen_TokenAddressIsZero(uint256 _amount, address _actor) external {
        // It should revert
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_InvalidToken.selector);

        tokenGatingExtension.call__checkOnlyWithToken(address(0), _amount, _actor);
    }

    function test_RevertWhen_ActorAddressIsZero(address _token, uint256 _amount) external {
        vm.assume(_token != address(0));
        vm.assume(_token != address(vm));
        assumeNotPrecompile(_token);

        // It should revert
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_InvalidActor.selector);

        tokenGatingExtension.call__checkOnlyWithToken(_token, _amount, address(0));
    }

    function test_RevertWhen_ActorBalanceIsLessThanAmount(
        address _token,
        uint256 _amount,
        uint256 _balance,
        address _actor
    ) external {
        vm.assume(_token != address(0));
        vm.assume(_actor != address(0));
        vm.assume(_balance < _amount);
        vm.assume(_token != address(vm));
        assumeNotPrecompile(_token);

        vm.mockCall(address(_token), abi.encodeWithSelector(IERC20.balanceOf.selector, _actor), abi.encode(_balance));

        // It should revert
        vm.expectRevert(TokenGatingExtension.TokenGatingExtension_InsufficientBalance.selector);

        tokenGatingExtension.call__checkOnlyWithToken(_token, _amount, _actor);
    }

    function test_WhenParametersAreValid(address _token, uint256 _amount, uint256 _balance, address _actor) external {
        vm.assume(_token != address(0));
        vm.assume(_actor != address(0));
        vm.assume(_balance > _amount);
        vm.assume(_token != address(vm));
        assumeNotPrecompile(_token);

        vm.mockCall(address(_token), abi.encodeWithSelector(IERC20.balanceOf.selector, _actor), abi.encode(_balance));

        // It should execute successfully
        tokenGatingExtension.call__checkOnlyWithToken(_token, _amount, _actor);
    }
}
