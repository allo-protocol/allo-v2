// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {MicroGrantsBaseStrategyTest} from "./MicroGrantsBaseStrategy.t.sol";
import {MicroGrantsStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsStrategy.sol";
import {MicroGrantsBaseStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsBaseStrategy.sol";

contract MicroGrantsStrategyTest is MicroGrantsBaseStrategyTest {
    function test_batchSetAllocator() public {
        address[] memory allocatorAddresses = new address[](2);
        allocatorAddresses[0] = profile1_member1();
        allocatorAddresses[1] = profile1_member2();

        bool[] memory allocatorValues = new bool[](2);
        allocatorValues[0] = true;
        allocatorValues[1] = true;

        vm.prank(pool_admin());
        MicroGrantsStrategy(_strategy).batchSetAllocator(allocatorAddresses, allocatorValues);
    }

    function __addAllocators() internal virtual override {
        __setAllocator(profile1_member1(), true);
        __setAllocator(profile1_member2(), true);
        __setAllocator(profile2_member1(), true);
        __setAllocator(profile2_member2(), true);
    }

    function __setAllocator(address allocator, bool value) internal override {
        vm.prank(pool_admin());
        MicroGrantsStrategy(_strategy).setAllocator(allocator, value);
    }

    function _createPoolWithCustomStrategy() internal virtual override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(useRegistryAnchor, allocationStartTime, allocationEndTime, approvalThreshold, maxRequestedAmount),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function _createStrategy() internal virtual override returns (address payable) {
        return payable(address(new MicroGrantsStrategy(address(allo()), "MicroGrantsStrategy")));
    }

    function test_setAllocator() public {
        __addAllocators();
    }

    function testRevert_setAllocator_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        MicroGrantsStrategy(_strategy).setAllocator(profile1_member1(), false);
    }

    function testRevert_allocate_UNAUTHORIZED() public override {
        address[] memory recipientIds = new address[](1);
        address recipientId = __registerRecipient();
        recipientIds[0] = recipientId;

        bytes memory allocationData = abi.encode(recipientId, IStrategy.Status.Accepted);

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(address(allo()));
        mgStrategy().allocate(allocationData, randomAddress());
    }
}
