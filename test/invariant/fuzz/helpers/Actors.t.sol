// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Minimal actors handler, reusing the msg.sender used by echidna (defined in the json)
// and tracking them, allowing to aggregate balances for instance
contract Actors {
    address[] internal _ghost_actorsArray;
    address internal _ghost_currentCaller;

    modifier useActor() {
        _ghost_currentCaller = msg.sender;
        _addActor(_ghost_currentCaller);
        _;
    }

    function changeActor() public {
        _ghost_currentCaller = msg.sender;
        _addActor(_ghost_currentCaller);
    }

    // Conditionnally add new msg sender (no duplicate)
    function _addActor(address _actor) internal {
        bool _previouslyUsed = false;
        for (uint256 i = 0; i < _ghost_actorsArray.length; i++) {
            if (_ghost_actorsArray[i] == _actor) {
                _previouslyUsed = true;
                break;
            }
        }

        if (!_previouslyUsed) _ghost_actorsArray.push(_actor);
    }
}
