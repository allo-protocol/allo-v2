// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import {Metadata} from "./libraries/Metadata.sol";

contract Registry is AccessControl {

    /// @notice Custom errors
    error NO_ACCESS_TO_ROLE();
    error NONCE_NOT_AVAILABLE();

    /// @notice Types of roles assigned to an identity
    enum RoleType {
        OWNER,
        MEMBER
    }

    /// @notice Struct to hold details of an identity
    struct Identity {
        uint nonce;
        string name;
        Metadata metadata;
        address anchor;
    }

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Identity.id -> Identity
    mapping(bytes32 => Identity) public identitiesById;

    /// @notice anchor -> Identity.id
    mapping(address => bytes32) public anchorToIdentityId;

    /// ======================
    /// ======= Events =======
    /// ======================

    event IdentityCreated(
        bytes32 indexed identityId,
        uint nonce,
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

    /// ====================================
    /// ========== Constructor =============
    /// ====================================
    constructor(address _admin) {
        // DEFAULT_ADMIN_ROLE would be set by Allo team
        // to grant or revoke roles in emergencies.
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// ====================================
    /// ========== Modifier =============
    /// ====================================
    modifier isPoolOwner(bytes32 _identityId) {
        if (!isOwnerOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Retrieve identity by identityId
    /// @param identityId The identityId of the identity
    function getIdentityById(bytes32 identityId) public view returns (Identity memory) {
        return identitiesById[identityId];
    }

    /// @notice Retrieve identity by anchor
    /// @param anchor The anchor of the identity
    function getIdentityByAnchor(address anchor) public view returns (Identity memory) {
        bytes32 identityId = anchorToIdentityId[anchor];
        return identitiesById[identityId];
    }

    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    /// @param _nonce Nonce used to generate identityId
    /// @param _name The name of the identity
    /// @param _metadata The metadata of the identity
    /// @param _owner The owner of the identity
    /// @param _members The members of the identity
    function createIdentity(
        uint _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32) {
        bytes32 identityId = _generateIdentityId(_nonce);

        if (identitiesById[identityId].nonce != 0) {
            revert NONCE_NOT_AVAILABLE();
        }

        Identity memory identity = Identity({
            nonce: _nonce,
            name: _name,
            metadata: _metadata,
            anchor: _generateAnchor(identityId, _name)
        });

        identitiesById[identityId] = identity;
        anchorToIdentityId[identity.anchor] = identityId;

        // generate roles
        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(identityId, RoleType.MEMBER);

        // assign roles
        _grantRole(ownerRole, _owner);

        uint256 memberLength = _members.length;
        for (uint i = 0; i < memberLength; ) {
            _grantRole(memberRole, _members[i]);
            unchecked {
                i++;
            }
        }

        emit IdentityCreated(
            identityId,
            identity.nonce,
            identity.name,
            identity.metadata,
            identity.anchor
        );

        return identityId;
    }

    /// @notice Updates the name of the identity and generates new anchor
    /// @param _identityId The identityId of the identity
    /// @param _name The new name of the identity
    /// @dev Only owner can update the name.
    function updateIdentityName(
        bytes32 _identityId,
        string memory _name
    ) external isPoolOwner(_identityId) returns (address) {

        address anchor = _generateAnchor(_identityId, _name);

        Identity storage identity = identitiesById[_identityId];
        identity.name = _name;
        identity.anchor = anchor;

        // TODO: should we clear old anchor?
        anchorToIdentityId[identity.anchor] = _identityId;

        emit IdentityNameUpdated(_identityId, _name, anchor);

        // TODO: should we return identity
        return anchor;
    }

    /// @notice update the metadata of the identity
    /// @param _identityId The identityId of the identity
    /// @param _metadata The new metadata of the identity
    /// @dev Only owner can update metadata
    function updateIdentityMetadata(
        bytes32 _identityId,
        Metadata memory _metadata
    ) external isPoolOwner(_identityId) {

        identitiesById[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isOwnerOfIdentity(
        bytes32 _identityId,
        address _owner
    ) public view returns (bool) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        return hasRole(ownerRole, _owner);
    }

    /// @notice Returns if the given address is an member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _member The address to check
    function isMemberOfIdentity(
        bytes32 _identityId,
        address _member
    ) public view returns (bool) {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);
        return hasRole(memberRole, _member);
    }

    // Note: Check with product if we can retain this function as if a role
    // can be granted, we should have a way to revoke / transfer ownership
    /// @notice Transfers the ownership of the identity to a new owner
    /// @param _identityId The identityId of the identity
    /// @param _owner New Owner
    /// @dev Only owner can transfer ownership.
    /// Note: both old and new owner will be members of the identity
    function changeIdentityOwner(
        bytes32 _identityId,
        address _owner
    ) external {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        _grantRole(ownerRole, _owner);
        _revokeRole(ownerRole, msg.sender);
    }


    /// @notice Adds members to the identity
    /// @param _identityId The identityId of the identity
    /// @param _members The members to add
    /// @dev Only owner can add members
    function addMembers(
        bytes32 _identityId,
        address[] memory _members
    ) external isPoolOwner(_identityId) {

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
    /// @dev Only owner can remove members
    function removeMembers(
        bytes32 _identityId,
        address[] memory _members
    ) external isPoolOwner(_identityId) {

        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        uint256 memberLength = _members.length;
        for (uint i = 0; i < memberLength; ) {
            _revokeRole(memberRole, _members[i]);
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ======== Internal Functions ========
    /// ====================================

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
    /// @param _nonce Nonce used to generate identityId
    function _generateIdentityId(uint _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, msg.sender));
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
}
