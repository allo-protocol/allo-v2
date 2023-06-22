// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import {Metadata} from "./libraries/Metadata.sol";

contract Registry is AccessControl {
    error NO_ACCESS_TO_ROLE();
    error NOT_SUPPORTED();

    /// @notice Unique identifier for an identity - a counter
    uint private identityId;

    /// @notice Types of roles assigned to an identity
    enum RoleType {
        OWNER,
        MEMBER
    }

    /// @notice Struct to hold details of an identity
    struct IdentityDetails {
        string name;
        Metadata metadata;
        address anchor;
    }

    /// @notice identityId -> IdentityDetails
    mapping(uint => IdentityDetails) public identities;

    // Events
    event IdentityCreated(
        uint indexed identityId,
        string name,
        Metadata metadata,
        address anchor
    );
    event IdentityNameUpdated(
        uint indexed identityId,
        string name,
        address newOwnerIdentifier
    );
    event IdentityMetadataUpdated(uint indexed identityId, Metadata metadata);

    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    /// @param name The name of the identity
    /// @param metadata The metadata of the identity
    /// @param _owners The owners of the identity
    /// @param _members The members of the identity
    function createIdentity(
        string memory name,
        Metadata memory metadata,
        address[] memory _owners,
        address[] memory _members
    ) external returns (uint256) {
        IdentityDetails memory identityDetails = IdentityDetails(
            name,
            metadata,
            _generateAnchor(name, msg.sender)
        );

        identities[identityId] = identityDetails;

        // generate roles
        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(identityId, RoleType.MEMBER);

        // assign roles
        // todo: check if both arrays are empty, we don't want to emit below if so.
        for (uint i = 0; i < _owners.length; i++) {
            _grantRole(ownerRole, _owners[i]);
        }
        for (uint i = 0; i < _members.length; i++) {
            _grantRole(memberRole, _members[i]);
        }

        // NOTE: should we use the identityDetails we created above or the data passed in?
        emit IdentityCreated(
            identityId,
            name,
            metadata,
            identityDetails.anchor
        );

        identityId++;

        return identityId;
    }

    /// @notice Updates the name of the identity.
    /// @param _identityId The identityId of the identity
    /// @param _name The new name of the identity
    /// @dev Only owner can update the name. Also updated the attestation address
    function updateIdentityName(
        uint _identityId,
        string memory _name
    ) external returns (address) {
        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        identities[_identityId].name = _name;
        identities[_identityId].anchor = _generateAnchor(
            _name,
            msg.sender
        );
        address anchor = identities[_identityId].anchor;

        emit IdentityNameUpdated(_identityId, _name, anchor);

        return anchor;
    }

    /// @notice update the metadata of the identity
    /// @param _identityId The identityId of the identity
    /// @param _metadata The new metadata of the identity
    /// @dev Only owner or member can update metadata
    function updateIdentityMetadata(
        uint _identityId,
        Metadata memory _metadata
    ) external {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        if (
            !hasRole(ownerRole, msg.sender) || !hasRole(memberRole, msg.sender)
        ) {
            revert NO_ACCESS_TO_ROLE();
        }

        identities[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isOwnerOfIdentity(
        uint _identityId,
        address _owner
    ) external view returns (bool) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        return hasRole(ownerRole, _owner);
    }

    /// @notice Returns if the given address is an member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isMemberOfIdentity(
        uint _identityId,
        address _owner
    ) external view returns (bool) {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);
        return hasRole(memberRole, _owner);
    }

    /// @notice Generates the attestation address for the given sender and name
    /// @dev This is a simple hash of the name and sender
    /// @param _name The name of the identity
    /// @param _sender The sender of the transaction
    function _generateAnchor(
        string memory _name,
        address _sender
    ) internal pure returns (address) {
        bytes32 attestationHash = keccak256(abi.encodePacked(_name, _sender));

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the OZ role for an given identity
    /// @dev This is a simple hash of the identityId and roleType
    /// @param _identityId The identityId of the identity
    /// @param _roleType The roleType of the identity
    function _generateRole(
        uint _identityId,
        RoleType _roleType
    ) internal pure returns (bytes32 roleHash) {
        roleHash = keccak256(abi.encodePacked(_identityId, _roleType));
    }

    // --- ACCESS CONTROL ---

    /// @notice OZ function to grant role reverts
    /// @dev This is not supported as we want to control the roles
    ///     through the createIdentity function
    /// @param role The role to grant
    /// @param account The account to grant the role to
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        revert NOT_SUPPORTED();
    }

    /// @notice OZ function to revoke role reverts
    /// @dev This is not supported as we want to control the roles
    ///     through the createIdentity function
    /// @param role The role to revoke
    /// @param account The account to revoke the role from
    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        revert NOT_SUPPORTED();
    }

    /// @notice function to grant role(s) to an identity (owner or member?)
    /// @dev
    /// @param _identityId The identityId of the identity
    /// @param _roleType The roleType of the identity
    /// @param account The account to grant the role to
    function grantIdentityRole(
        uint _identityId,
        RoleType _roleType,
        address account
    ) external returns (uint) {
        bytes32 role = _generateRole(_identityId, _roleType);
        _grantRole(role, account);

        if (_roleType == RoleType.OWNER) {
            IdentityDetails memory identity = identities[_identityId];
            // TODO: HOW to update attestation address cause name and identityId is never updated?
            // NOTE: see comment: https://github.com/allo-protocol/allo-v2/pull/12#discussion_r1238843703
        }
        return _identityId;
    }

    /// @notice function to revoke role(s) to an identity (owner or member?)
    /// @dev Internal function to revoke role(s) to an identity (owner or member?)
    /// @param _identityId The identityId of the identity
    /// @param _roleType The roleType of the identity
    /// @param account The account to grant the role to
    function revokeIdentityRole(
        uint _identityId,
        RoleType _roleType,
        address account
    ) external returns (uint) {
        bytes32 role = _generateRole(_identityId, _roleType);
        _revokeRole(role, account);
        if (_roleType == RoleType.OWNER) {
            IdentityDetails memory identity = identities[_identityId];
            // TODO: How to update attestation address cause name and identityId is never updated?
            // NOTE: see comment: https://github.com/allo-protocol/allo-v2/pull/12#discussion_r1238843703
        }
        return _identityId;
    }
}
