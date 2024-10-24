// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlerAllo, IAllo} from "./HandlerAllo.t.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract HandlerStrategy is HandlerAllo {
    function handler_withdraw(uint256 _poolSeed, uint256 _amount) public {
        address _recipient = makeAddr("IAmRecipient");

        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        // Get the pool
        _poolSeed = _poolSeed % ghost_poolIds.length;
        IAllo.Pool memory _pool = allo.getPool(ghost_poolIds[_poolSeed]);

        // Withdraw
        (bool succ,) = targetCall(
            address(allo), 0, abi.encodeCall(strategy_directAllocation.withdraw, (_pool.token, _amount, _recipient))
        );
    }
}
