pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {BaseStrategy} from "../../../../contracts/strategies/BaseStrategy.sol";

contract BaseAllocationStrategyTest is Test {
    function test_initialize() public {
        // Todo: test that the contract is initialized correctly
    }

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {
        //  Todo:
    }
}
