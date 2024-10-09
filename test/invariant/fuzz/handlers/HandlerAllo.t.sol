// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";

contract HandlerAllo is Setup {
    function handler_createPool() public useActor {
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            msg.sender
        );

        vm.prank(msg.sender);

        // Create a pool

        uint256 poolId = allo.createPool();
    }
}
