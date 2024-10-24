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
//
// Profile Owners (manage members and create pools) - 7 (we track one strat of each, testing "can always create pool" can be with a pool with then drop)
// Profile Member (create pools) - 1
// (- Pool Creator) -> profile owner or member

// Pool Administrator (manage managers, like the assistant TO the regional manager or smth) - 1

// Pool Manager (withdraw based on strat, update metadata) - 1

// Recipient (get the chicken) - 2 (one auth and one non-auth/has no allocation)?

// Maybe "donator" which are external too? (ie funding the pool) - 1 (and 7th is for the allo owner, which would be a profile owner too)

// protocol/allo owner is a single one, so a bit special case. Plus 7 strategies, big space...
contract Actors is Utils {
    address[] internal _ghost_actors = [
        address(0x10000),
        address(0x20000),
        address(0x30000),
        address(0x40000),
        address(0x50000),
        address(0x60000),
        address(0x70000),
        address(0x80000),
        address(0x90000),
        address(0xa0000)
    ];

    mapping(address actor => address anchor) internal _ghost_anchorOf;
    mapping(bytes32 profileId => address actor) internal _ghost_profileIdToActor;

    // switch between using the anchor or an EOA as msg.sender for the call to target
    bool internal _usingAnchor;

    event ActorsLog(string);

    // toggle eoa vs anchor as sender
    function handler_anchorActorSwitch() public {
        _usingAnchor = !_usingAnchor;

        // This event if for forge, as medusa will not show it in failed trace (no revert)
        emit ActorsLog(string.concat("using anchor: ", vm.toString(_usingAnchor)));
    }

    // Handle the actual call, from an EOA or anchor
    function targetCall(address target, uint256 msgValue, bytes memory payload)
        internal
        returns (bool success, bytes memory returnData)
    {
        address anchorOwner = msg.sender;
        address anchor = _ghost_anchorOf[anchorOwner];

        if (_usingAnchor) {
            if (anchor == address(0)) revert();

            emit ActorsLog(string.concat("call using anchor of ", vm.toString(anchorOwner)));

            vm.deal(anchor, msgValue);

            vm.prank(anchorOwner);
            (success, returnData) = address(anchor).call(abi.encodeCall(Anchor.execute, (target, msgValue, payload)));
        } else {
            emit ActorsLog(string.concat("call using EOA ", vm.toString(anchorOwner)));

            // vm.deal(anchorOwner, msgValue);
            payable(anchorOwner).transfer(msgValue);

            emit ActorsLog(vm.toString(anchorOwner.balance));

            vm.prank(anchorOwner);
            (success, returnData) = address(target).call{value: msgValue}(payload);
        }
    }

    function targetCallDefault(address target, uint256 msgValue, bytes memory payload)
        internal
        returns (bool success, bytes memory returnData)
    {
        return targetCall({target: target, sender: msg.sender, msgValue: msgValue, payload: payload});
    }

    function targetCall(address target, address sender, uint256 msgValue, bytes memory payload)
        internal
        returns (bool success, bytes memory returnData)
    {
        emit ActorsLog(string.concat("call using EOA ", vm.toString(sender)));

        vm.deal(sender, msgValue);
        payable(sender).transfer(msgValue);

        emit ActorsLog(vm.toString(sender.balance));

        vm.prank(sender);
        (success, returnData) = address(target).call{value: msgValue}(payload);
    }

    function _addAnchorToActor(address _actor, address _anchor, bytes32 _profileId) internal {
        _ghost_anchorOf[_actor] = _anchor;
        _ghost_profileIdToActor[_profileId] = _actor;
    }

    function _removeAnchorFromActor(address _actor, bytes32 _profileId) internal {
        delete _ghost_anchorOf[_actor];
        delete _ghost_profileIdToActor[_profileId];
    }
}
