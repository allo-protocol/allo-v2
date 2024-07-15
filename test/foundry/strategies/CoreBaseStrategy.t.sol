pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {MockBaseStrategy} from "../../utils/MockBaseStrategy.sol";

// Core contracts
import {IBaseStrategy} from "../../../contracts/core/interfaces/IBaseStrategy.sol";
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";

contract CoreBaseStrategyTest is Test, AlloSetup {
    MockBaseStrategy strategy;

    function setUp() public {
        __AlloSetup(makeAddr("registry"));

        strategy = new MockBaseStrategy(address(allo()));
    }

    function testRevert_initialize_INVALID_zeroPoolId() public {
        vm.expectRevert(IBaseStrategy.BaseStrategy_INVALID_POOL_ID.selector);

        vm.prank(address(allo()));
        strategy.initialize(0, "");
    }

    function test_getAllo() public {
        assertEq(address(strategy.getAllo()), address(allo()));
    }

    function test_getPoolId() public {
        assertEq(strategy.getPoolId(), 0);
    }

    function test_getPoolAmount() public {
        assertEq(strategy.getPoolAmount(), 0);
    }

    function test_increasePoolAmount() public {
        vm.prank(address(allo()));
        strategy.increasePoolAmount(100);
        assertEq(strategy.getPoolAmount(), 100);
    }
}
