pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/Allo.sol";
import {IStrategy} from "../../../contracts/strategies/IStrategy.sol";
// Core contracts
import {BaseStrategy} from "../../../contracts/strategies/BaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/donation-voting/DonationVotingStrategy.sol";
// Internal libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {MockStrategy} from "../utils/MockStrategy.sol";

import {EventSetup} from "../shared/EventSetup.sol";

contract BaseStrategyTest is Test, AlloSetup, RegistrySetupFull {
    MockStrategy strategy;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategy = new MockStrategy(address(allo()));
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
