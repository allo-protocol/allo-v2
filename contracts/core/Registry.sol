// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import {Metadata} from "./libraries/Metadata.sol";

contract Registry is AccessControl {
    error NO_ACCESS_TO_ROLE();
    // error NOT_ALLOWED();

    /// @notice Maps msg.sender addresses to nonces to generate identityId
    mapping (address => uint) public senderNonceMap;

    /// @notice Types of roles assigned to an identity
    enum RoleType {
        OWNER,
        MEMBER
    }

    /// @notice Struct to hold details of an identity
    struct Identity {
        bytes32 id;
        string name;
        Metadata metadata;
        address anchor;
    }

    /// @notice identityId -> Identity
    mapping(bytes32 => Identity) public identities;

    // Events
    event IdentityCreated(
        bytes32 indexed identityId,
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
    /// @param _name The name of the identity
    /// @param _metadata The metadata of the identity
    /// @param _owners The owners of the identity
    /// @param _members The members of the identity
    function createIdentity(
        string memory _name,
        Metadata memory _metadata,
        address[] memory _owners,
        address[] memory _members
    ) external returns (bytes32) {

        bytes32 _identityId = _generateIdentityId();

        Identity memory identity = Identity(
            _identityId,
            _name,
            _metadata,
            _generateAnchor(_identityId, _name)
        );

        identities[_identityId] = identity;

        // generate roles
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        // assign roles
        // todo: check if both arrays are empty, we don't want to emit below if so.
        for (uint i = 0; i < _owners.length; i++) {
            _grantRole(ownerRole, _owners[i]);
        }
        for (uint i = 0; i < _members.length; i++) {
            _grantRole(memberRole, _members[i]);
        }

        emit IdentityCreated(
            identity.id,
            identity.name,
            identity.metadata,
            identity.anchor
        );

        // increment nonce
        senderNonceMap[msg.sender] = senderNonceMap[msg.sender] + 1;

        return _identityId;
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

        identities[_identityId].name = _name;
        identities[_identityId].anchor = _generateAnchor(
            _identityId,
            _name
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
        bytes32 _identityId,
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
        bytes32 _identityId,
        address _owner
    ) external view returns (bool) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        return hasRole(ownerRole, _owner);
    }

    /// @notice Returns if the given address is an member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isMemberOfIdentity(
        bytes32 _identityId,
        address _owner
    ) external view returns (bool) {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);
        return hasRole(memberRole, _owner);
    }

    /// @notice Generates the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _generateAnchor(
        bytes32 _identityId,
        string memory _name
    ) internal pure returns (address) {
        bytes32 attestationHash = keccak256(abi.encodePacked(_identityId, _name));

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the identityId based on msg.sender
    function _generateIdentityId() internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                msg.sender,
                senderNonceMap[msg.sender]
            )
        );
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

    // // --- ACCESS CONTROL ---

    // /// @notice OZ function to grant role reverts
    // /// @dev Use grantIdentityRoles instead
    // /// @param role The role to grant
    // /// @param account The account to grant the role to
    // function grantRole(bytes32 role, address account) public virtual override {
    //     revert NOT_ALLOWED();
    // }

    // /// @notice OZ function to revoke role reverts
    // /// @dev Use revokeIdentityRoles instead
    // /// @param role The role to revoke
    // /// @param account The account to revoke the role from
    // function revokeRole(bytes32 role, address account) public virtual override {
    //     revert NOT_ALLOWED();
    // }

    // /// @notice function to grant role(s) to an identity (owner or member?)
    // /// @dev
    // /// @param _identityId The identityId of the identity
    // /// @param _roleType The roleType of the identity
    // /// @param account The account to grant the role to
    // function grantIdentityRoles(
    //     uint _identityId,
    //     RoleType _roleType,
    //     address[] accounts
    // ) external returns (uint) {
    //     bytes32 isOwner = hasRole(
    //         _generateRole(_identityId, RoleType.OWNER),
    //         msg.sender
    //     );
    //     if (!isOwner) {
    //         revert NO_ACCESS_TO_ROLE();
    //     }

    //     bytes32 role = _generateRole(_identityId, _roleType);

    //     // assign role        
    //     for (uint i = 0; i < accounts.length; i++) {
    //         _grantRole(role, accounts[i]);
    //     }

    //     // create new identityId
    //     if (_roleType == RoleType.OWNER) {
           
    //     }
    //     return _identityId;
    // }

    // /// @notice function to revoke role(s) to an identity (owner or member?)
    // /// @dev Internal function to revoke role(s) to an identity (owner or member?)
    // /// @param _identityId The identityId of the identity
    // /// @param _roleType The roleType of the identity
    // /// @param account The account to grant the role to
    // function revokeIdentityRoles(
    //     uint _identityId,
    //     RoleType _roleType,
    //     address account
    // ) external returns (uint) {
    //     bytes32 role = _generateRole(_identityId, _roleType);
    //     _revokeRole(role, account);
    //     if (_roleType == RoleType.OWNER) {
    //         Identity memory identity = identities[_identityId];
    //         // TODO: How to update attestation address cause name and identityId is never updated?
    //         // NOTE: see comment: https://github.com/allo-protocol/allo-v2/pull/12#discussion_r1238843703
    //     }
    //     return _identityId;
    // }
}
