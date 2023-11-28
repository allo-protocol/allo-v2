// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {MicroGrantsBaseStrategyTest} from "./MicroGrantsBaseStrategy.t.sol";
import {MicroGrantsGovStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsGovStrategy.sol";
import {MicroGrantsBaseStrategy} from "../../../contracts/strategies/_poc/micro-grants/MicroGrantsBaseStrategy.sol";
import {MockUniversalGov} from "../../utils/MockUniversalGov.sol";

contract MicroGrantsGovStrategyTest is MicroGrantsBaseStrategyTest {
    MockUniversalGov public GOV;

    uint256 minVotePower = 1000;

    function setUp() public override {
        vm.warp(5 days);
        vm.roll(20);
        GOV = new MockUniversalGov();
        super.setUp();
    }

    function testRevert_initialize_INVALID() public {
        address payable newStrategy = _createStrategy();
        vm.prank(pool_admin());
        vm.expectRevert(INVALID.selector);
        allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(newStrategy),
            abi.encode(
                useRegistryAnchor,
                allocationStartTime,
                allocationEndTime,
                approvalThreshold,
                maxRequestedAmount,
                address(GOV),
                0,
                minVotePower
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );

        vm.prank(pool_admin());
        vm.expectRevert(INVALID.selector);
        allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(newStrategy),
            abi.encode(
                useRegistryAnchor,
                allocationStartTime,
                allocationEndTime,
                approvalThreshold,
                maxRequestedAmount,
                address(GOV),
                123,
                0
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function __addAllocators() internal virtual override {
        __setAllocator(profile1_member1(), true);
        __setAllocator(profile1_member2(), true);
        __setAllocator(profile2_member1(), true);
        __setAllocator(profile2_member2(), true);
    }

    function __setAllocator(address allocator, bool value) internal override {
        vm.prank(pool_admin());
        if (value) {
            GOV.add(allocator, 1001);
        } else {
            GOV.add(allocator, 1);
        }
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
                address(GOV),
                123,
                minVotePower
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    function _createStrategy() internal virtual override returns (address payable) {
        return payable(address(new MicroGrantsGovStrategy(address(allo()), "MicroGrantsStrategy")));
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
