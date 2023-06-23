// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import {Metadata} from "./libraries/Metadata.sol";

contract Registry is AccessControl {
    error NO_ACCESS_TO_ROLE();
    error INDEX_NOT_AVAILABLE();

    /// @notice Types of roles assigned to an identity
    enum RoleType {
        OWNER,
        MEMBER
    }

    /// @notice Struct to hold details of an identity
    struct Identity {
        bytes32 id;
        uint index;
        string name;
        Metadata metadata;
        address anchor;
    }

    /// @notice Identity.id -> Identity
    mapping(bytes32 => Identity) public identitiesById;

    /// @notice anchor -> Identity.id
    mapping(address => bytes32) public anchorToIdentityId;

    // Events
    event IdentityCreated(
        bytes32 indexed identityId,
        uint index,
        string name,
        Metadata metadata,
        address anchor
    );
    event IdentityNameUpdated(
        bytes32 indexed identityId,
        string name,
        address anchor
    );
    event IdentityMetadataUpdated(
        bytes32 indexed identityId,
        Metadata metadata
    );

    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    /// @param _index Index of the identity
    /// @param _name The name of the identity
    /// @param _metadata The metadata of the identity
    /// @param _owner The owner of the identity
    /// @param _members The members of the identity
    function createIdentity(
        uint _index,
        string memory _name,
        Metadata memory _metadata,
        address _owner, // Note: this is a single owner
        address[] memory _members
    ) external returns (bytes32) {
        bytes32 identityId = _generateIdentityId(_index);

        if (identitiesById[identityId].id == bytes32(0)) {
            revert INDEX_NOT_AVAILABLE();
        }

        Identity memory identity = Identity(
            identityId,
            _index,
            _name,
            _metadata,
            _generateAnchor(identityId, _name)
        );

        identitiesById[identityId] = identity;
        anchorToIdentityId[identity.anchor] = identityId;

        // generate roles
        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(identityId, RoleType.MEMBER);

        // assign roles
        address owner = _owner;
        _grantRole(ownerRole, owner);
        _grantRole(memberRole, owner);

        uint256 memberLength = _members.length;
        for (uint i = 0; i < memberLength; ) {
            _grantRole(memberRole, _members[i]);
            unchecked {
                i++;
            }
        }

        emit IdentityCreated(
            identity.id,
            identity.index,
            identity.name,
            identity.metadata,
            identity.anchor
        );

        return identityId;
    }

    /// @notice Updates the name of the identity and generates new anchor
    /// @param _identityId The identityId of the identity
    /// @param _name The new name of the identity
    /// @dev Only owner can update the name. _identityId is reused.
    function updateIdentityName(
        bytes32 _identityId,
        string memory _name
    ) external returns (address) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        address anchor = _generateAnchor(_identityId, _name);

        Identity storage identity = identitiesById[_identityId];
        identity.name = _name;
        identity.anchor = anchor;

        emit IdentityNameUpdated(_identityId, _name, anchor);

        // TODO: should we return identity
        return anchor;
    }

    /// @notice update the metadata of the identity
    /// @param _identityId The identityId of the identity
    /// @param _metadata The new metadata of the identity
    /// @dev Only owner or member can update metadata
    function updateIdentityMetadata(
        bytes32 _identityId,
        Metadata memory _metadata
    ) external {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        if (!hasRole(memberRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        identitiesById[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isOwnerOfIdentity(
        bytes32 _identityId,
        address _owner
    ) external view returns (bool) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        return hasRole(ownerRole, _owner);
    }

    /// @notice Returns if the given address is an member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _member The address to check
    function isMemberOfIdentity(
        bytes32 _identityId,
        address _member
    ) external view returns (bool) {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);
        return hasRole(memberRole, _member);
    }

    /// @notice Generates the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _generateAnchor(
        bytes32 _identityId,
        string memory _name
    ) internal pure returns (address) {
        bytes32 attestationHash = keccak256(
            abi.encodePacked(_identityId, _name)
        );

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the identityId based on msg.sender
    /// @param _index Index of the identity
    function _generateIdentityId(uint _index) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, _index));
    }

    /// @notice Generates the OZ role for an given identity
    /// @param _identityId The identityId of the identity
    /// @param _roleType The roleType of the identity
    function _generateRole(
        bytes32 _identityId,
        RoleType _roleType
    ) internal pure returns (bytes32 roleHash) {
        roleHash = keccak256(abi.encodePacked(_identityId, _roleType));
    }

    // Note: Role management - Spoke with Nate, we are going to go with single owner for now
    // ! Who can add / remove owner for an identity? No one. It's a single owner.
    // ? Transfer ownership will not be supported for now.
    // - Owner can add / remove members
    // - Single owner

    /// @notice Adds members to the identity
    /// @param _identityId The identityId of the identity
    /// @param _members The members to add
    function addMembers(
        bytes32 _identityId,
        address[] memory _members
    ) external {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        uint256 memberLength = _members.length;
        for (uint i = 0; i < memberLength; ) {
            _grantRole(memberRole, _members[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Removes members from the identity
    /// @param _identityId The identityId of the identity
    /// @param _members The members to remove
    function removeMembers(
        bytes32 _identityId,
        address[] memory _members
    ) external {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        uint256 memberLength = _members.length;
        for (uint i = 0; i < memberLength; ) {
            _revokeRole(memberRole, _members[i]);
            unchecked {
                i++;
            }
        }
    }
}
