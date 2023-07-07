pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../../../contracts/strategies/allocation/BaseAllocationStrategy.sol";

contract BaseAllocationStrategyTest is Test {
    function test_initialize() public {
        // Todo: test that the contract is initialized correctly
    }

    function testRevert_initialize_STRATEGY_ALREADY_INITIALIZED() public {
        //  Todo:
    }
}
