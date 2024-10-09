// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";
import {IAllo, Metadata} from "contracts/core/Allo.sol";

contract HandlerAllo is Setup {
    uint256[] ghost_poolIds;

    function handler_createPool(uint256 _msgValue) public {
        // Create a pool
        (bool succ, bytes memory ret) = targetCall(
            address(allo),
            _msgValue,
            abi.encodeWithSelector(
                IAllo.createPool.selector,
                bytes32(0),
                address(strategy_directAllocation),
                bytes(""),
                address(0),
                0,
                Metadata(0, ""),
                new address[](0)
            )
        );

        if (succ) ghost_poolIds.push(abi.decode(ret, (uint256)));
    }
}
