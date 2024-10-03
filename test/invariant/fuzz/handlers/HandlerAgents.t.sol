// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// Minimal agents handler, reusing the msg.sender used by echidna (defined in the json)
// and tracking them, allowing to aggregate balances for instance
contract HandlerAgents {
  address[] internal _ghost_agentsArray;
  address internal _ghost_currentCaller;

  modifier useAgent() {
    _ghost_currentCaller = msg.sender;

    bool _previouslyUsed = false;
    for (uint256 i = 0; i < _ghost_agentsArray.length; i++) {
      if (_ghost_agentsArray[i] == msg.sender) {
        _previouslyUsed = true;
        break;
      }
    }

    if(!_previouslyUsed) _ghost_agentsArray.push(msg.sender);

    _;
  }

  function aggregateAgentsBalance(IERC20 token) public view returns (uint256) {
    uint256 _balance = 0;
    for (uint256 i = 0; i < _ghost_agentsArray.length; i++) {
      _balance += token.balanceOf(_ghost_agentsArray[i]);
    }
    return _balance;
  }
}
