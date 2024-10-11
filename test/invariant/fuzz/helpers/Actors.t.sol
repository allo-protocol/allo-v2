// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {Anchor} from "contracts/core/Anchor.sol";

// Actors handler, reusing the msg.sender used by echidna (defined in the json)
// and tracking them, allowing to aggregate balances for instance.
//
// This tracks both EOA and anchors.
//
// This is handling the address making the call
// to the target contract, anchor are called by their owner only (for now?)
//
// For convenience, EOA used all have an anchor (most calls from the EOA to allo
// should revert, in most properties, anyway)
contract Actors is Utils {
    address[] internal _ghost_actorsArray;
    mapping(address actor => address anchor) internal _ghost_anchorOf;

    // switch between using the anchor or an EOA as msg.sender for the call to target
    bool internal _usingAnchor;

    event ActorsLog(string);

    // toggle eoa vs anchor as sender
    function handler_anchorActorSwitch() public {
        _usingAnchor = !_usingAnchor;

        // This event if for forge, as medusa will not show it in failed trace (no revert)
        emit ActorsLog(
            string.concat("using anchor: ", vm.toString(_usingAnchor))
        );
    }

    // Handle the actual call, from an EOA or anchor
    function targetCall(
        address target,
        uint256 msgValue,
        bytes memory payload
    ) internal returns (bool success, bytes memory returnData) {
        address anchorOwner = msg.sender;
        address anchor = _ghost_anchorOf[anchorOwner];

        // Every EOA should have an anchor, second check is probably not needed
        if (_usingAnchor && anchor != address(0)) {
            emit ActorsLog(
                string.concat("call using anchor of ", vm.toString(anchorOwner))
            );

            vm.deal(anchor, msgValue);

            vm.prank(anchorOwner);
            (success, returnData) = address(anchor).call(
                abi.encodeCall(Anchor.execute, (target, msgValue, payload))
            );
        } else {
            emit ActorsLog(
                string.concat("call using EOA ", vm.toString(anchorOwner))
            );

            // vm.deal(anchorOwner, msgValue);
            payable(anchorOwner).transfer(msgValue);

            emit ActorsLog(vm.toString(anchorOwner.balance));

            vm.prank(anchorOwner);
            (success, returnData) = address(target).call{value: msgValue}(
                payload
            );
        }
    }

    // Conditionnally add new msg sender (no duplicate)
    function _addActorAndAnchor(address _actor, address _anchor) internal {
        bool _previouslyUsed = false;
        for (uint256 i = 0; i < _ghost_actorsArray.length; i++) {
            if (_ghost_actorsArray[i] == _actor) {
                _previouslyUsed = true;
                break;
            }
        }

        if (!_previouslyUsed) {
            _ghost_actorsArray.push(_actor);
            _ghost_anchorOf[_actor] = _anchor;
        }
    }
}
