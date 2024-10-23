// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup, Metadata} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";

contract HandlerRegistry is Setup {
    uint256 internal _ghost_nonce;
    bytes32[] internal _ghost_pendingOwnershipChange;
    mapping(bytes32 _profileId => address[] _members) internal _ghost_roleMembers;

    // create a new profile and discard it for now
    function handler_createProfile(uint256 _numberOfMembers) public {
        _numberOfMembers = bound(_numberOfMembers, 0, _ghost_actors.length);

        address[] memory _members = new address[](_numberOfMembers);
        for (uint256 i = 0; i < _numberOfMembers; i++) {
            _members[i] = _ghost_actors[i];
        }

        // Create a profile
        (bool succ, bytes memory ret) = targetCall(
            address(registry),
            0,
            abi.encodeWithSelector(
                registry.createProfile.selector,
                ++_ghost_nonce,
                "",
                Metadata({protocol: _ghost_nonce, pointer: ""}),
                msg.sender,
                _members
            )
        );
    }

    function handler_updateProfileName(string memory _newName) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        // will not succeed if no profile
        (bool succ, bytes memory ret) = targetCall(
            address(registry), 0, abi.encodeWithSelector(registry.updateProfileName.selector, profile.id, _newName)
        );
    }

    function handler_updateProfileMetadata(uint256 _newProtocol, string memory _newPtr) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        (bool succ, bytes memory ret) = targetCall(
            address(registry),
            0,
            abi.encodeWithSelector(
                registry.updateProfileMetadata.selector,
                profile.id,
                Metadata({protocol: _newProtocol, pointer: _newPtr})
            )
        );
    }

    function handler_updateProfilePendingOwner(uint256 _newOwnerSeed) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        // Get an actor as future owner
        address _newOwner = _ghost_actors[_newOwnerSeed % _ghost_actors.length];

        (bool succ, bytes memory ret) = targetCall(
            address(registry),
            0,
            abi.encodeWithSelector(registry.updateProfilePendingOwner.selector, profile.id, _newOwner)
        );

        if (succ) {
            _ghost_pendingOwnershipChange.push(profile.id);
        }
    }

    function handler_acceptProfileOwnership(uint256 _profileSeed) public {
        bytes32 _profileId = _ghost_pendingOwnershipChange[_profileSeed % _ghost_pendingOwnershipChange.length];

        if (_profileId == 0) {
            return;
        }

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileById(_profileId);

        (bool succ, bytes memory ret) = targetCall(
            address(registry), 0, abi.encodeWithSelector(registry.acceptProfileOwnership.selector, profile.id)
        );

        if (succ) {
            address _previousActor = _ghost_profileIdToActor[profile.id];
            _removeAnchorFromActor(_previousActor, profile.id);
            _addAnchorToActor(msg.sender, profile.anchor, profile.id);
            delete _ghost_pendingOwnershipChange[_profileSeed % _ghost_pendingOwnershipChange.length];
        }
    }

    function handler_addMembers(uint256 _seed) public {
        uint256 _membersToAdd = _seed % _ghost_actors.length;
        address[] memory _members = new address[](_membersToAdd);
        for (uint256 i = 0; i < _membersToAdd; i++) {
            _members[i] = _ghost_actors[i];
        }

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        (bool succ, bytes memory ret) =
            targetCall(address(registry), 0, abi.encodeWithSelector(registry.addMembers.selector, profile.id, _members));

        if (succ) {
            for (uint256 i = 0; i < _membersToAdd; i++) {
                _ghost_roleMembers[profile.id].push(_members[i]);
            }
        }
    }

    function handler_removeMembers(uint256 _seed) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        uint256 _membersToRemove = _seed % _ghost_roleMembers[profile.id].length;

        address[] memory _members = new address[](_membersToRemove);
        for (uint256 i = 0; i < _membersToRemove; i++) {
            _members[i] = _ghost_roleMembers[profile.id][i];
        }

        (bool succ, bytes memory ret) = targetCall(
            address(registry), 0, abi.encodeWithSelector(registry.removeMembers.selector, profile.id, _members)
        );

        // keep only the non-removed members in the ghost array
        if (succ) {
            address[] memory _nonRemovedMembers =
                new address[](_ghost_roleMembers[profile.id].length - _membersToRemove);

            for (uint256 i = 0; i < _nonRemovedMembers.length; i++) {
                _nonRemovedMembers[i] = _ghost_roleMembers[profile.id][i + _membersToRemove];
            }
        }
    }
}
