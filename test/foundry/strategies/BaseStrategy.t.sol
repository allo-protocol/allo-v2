pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {MockStrategy} from "../../utils/MockStrategy.sol";

// Core contracts
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

contract BaseStrategyTest is Test, AlloSetup, RegistrySetupFull, Errors {
    MockStrategy strategy;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategy = new MockStrategy(address(allo()));
    }

    function testRevert_initialize_INVALID_zeroPoolId() public {
        vm.expectRevert(INVALID.selector);

        vm.prank(address(allo()));
        strategy.initialize(0, "");
    }

    function test_getAllo() public {
        assertEq(address(strategy.getAllo()), address(allo()));
    }

    function test_getPoolId() public {
        assertEq(strategy.getPoolId(), 0);
    }

    function test_getStrategyId() public {
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("MockStrategy")));
    }

    function test_getPoolAmount() public {
        assertEq(strategy.getPoolAmount(), 0);
    }

    function test_isPoolActive() public {
        assertFalse(strategy.isPoolActive());
    }

    function test_setPoolActive() public {
        strategy.setPoolActive(true);
        assertTrue(strategy.isPoolActive());
    }

    function test_increasePoolAmount() public {
        vm.prank(address(allo()));
        strategy.increasePoolAmount(100);
        assertEq(strategy.getPoolAmount(), 100);
    }
}
