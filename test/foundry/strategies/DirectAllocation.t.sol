// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

// STrategy contract
import {DirectAllocationStrategy} from "../../../contracts/strategies/direct-allocation/DirectAllocation.sol";

// Core libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

// import ERC20 mocks
import {MockERC20} from "../../utils/MockERC20.sol";

contract DirectAllocationStrategyTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    MockERC20 internal mockERC20;
    DirectAllocationStrategy internal strategy;
    uint256 internal poolId;
    Metadata internal poolMetadata;

    event DirectAllocated(
        bytes32 indexed profileId, address profileOwner, uint256 amount, address token, address sender
    );

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategy = DirectAllocationStrategy(_deployStrategy());
        mockERC20 = new MockERC20();
        mockERC20.mint(address(this), 1_000_000 * 1e18);
        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(), address(strategy), bytes("0"), address(0), 0, poolMetadata, pool_managers()
        );
    }

    function _deployStrategy() internal virtual returns (address payable) {
        return payable(address(new DirectAllocationStrategy(address(allo()), "DirectAllocationStrategyStrategy")));
    }

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
    }

    function test_allocate_NATIVE() public {
        bytes memory data = abi.encode(profile1_owner(), 1000, NATIVE, 0);

        uint256 balanceBefore = profile1_owner().balance;

        vm.expectEmit(true, true, true, false);
        emit DirectAllocated(profile1_id(), profile1_owner(), 1000, NATIVE, address(this));

        allo().allocate{value: 1000}(poolId, data);

        uint256 balanceAfter = profile1_owner().balance;

        assertEq(balanceAfter, balanceBefore + 1000);
    }

    function test_allocate_ERC20() public {
        bytes memory data = abi.encode(profile1_owner(), 1000, address(mockERC20), 0);

        mockERC20.approve(address(strategy), 1000);

        uint256 balanceBefore = mockERC20.balanceOf(profile1_owner());

        vm.expectEmit(true, true, true, false);
        emit DirectAllocated(profile1_id(), profile1_owner(), 1000, address(mockERC20), address(this));

        allo().allocate(poolId, data);

        uint256 balanceAfter = mockERC20.balanceOf(profile1_owner());

        assertEq(balanceAfter, balanceBefore + 1000);
    }

    function test_withdraw_ERC20() public {
        uint256 balanceBefore1 = mockERC20.balanceOf(address(strategy));

        mockERC20.transfer(address(strategy), 1000);

        uint256 balanceAfter1 = mockERC20.balanceOf(address(strategy));
        uint256 balanceBefore2 = mockERC20.balanceOf(pool_admin());

        vm.prank(pool_admin());

        strategy.withdraw(address(mockERC20), pool_admin());

        uint256 balanceAfter2 = mockERC20.balanceOf(pool_admin());
        uint256 finalStrategyBalance = mockERC20.balanceOf(address(strategy));

        assertEq(balanceAfter1, balanceBefore1 + 1000);
        assertEq(balanceAfter2, balanceBefore2 + 1000);
        assertEq(finalStrategyBalance, 0);
    }

    function test_wirthdraw_revert_UNAUTHORIZED() public {
        mockERC20.transfer(address(strategy), 1000);

        vm.expectRevert(UNAUTHORIZED.selector);
        strategy.withdraw(address(mockERC20), pool_admin());
    }
}
