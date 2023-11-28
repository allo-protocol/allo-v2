// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {MicroGrantsBaseStrategyTest} from "./MicroGrantsBaseStrategy.t.sol";
import {MicroGrantsHatsStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsHatsStrategy.sol";
import {MicroGrantsBaseStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsBaseStrategy.sol";
import {MockHats} from "../../utils/MockHats.sol";

contract MicroGrantsHatsStrategyTest is MicroGrantsBaseStrategyTest {
    MockHats public HAT;

    function setUp() public override {
        HAT = new MockHats();
        super.setUp();
    }

    function __addAllocators() internal virtual override {
        __setAllocator(profile1_member1(), true);
        __setAllocator(profile1_member2(), true);
        __setAllocator(profile2_member1(), true);
        __setAllocator(profile2_member2(), true);
    }

    function __setAllocator(address allocator, bool value) internal override {
        vm.prank(pool_admin());
        HAT.addHat(allocator, value);
    }

    function testRevert_initialize_ZERO_ADDRESS() public {
        address payable newStrategy = _createStrategy();
        vm.prank(pool_admin());
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(newStrategy),
            abi.encode(
                useRegistryAnchor,
                allocationStartTime,
                allocationEndTime,
                approvalThreshold,
                maxRequestedAmount,
                address(0),
                123
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function _createPoolWithCustomStrategy() internal virtual override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                useRegistryAnchor,
                allocationStartTime,
                allocationEndTime,
                approvalThreshold,
                maxRequestedAmount,
                address(HAT),
                123
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function _createStrategy() internal virtual override returns (address payable) {
        return payable(address(new MicroGrantsHatsStrategy(address(allo()), "MicroGrantsStrategy")));
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
