// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import { Metadata } from "./libraries/Metadata.sol";

contract Registry is AccessControl {

    error NO_ACCESS_TO_ROLE();

    /// @notice Unique identifier for an identity
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
        address attestationAddr;
    }

    /// @notice identityId -> IdentityDetails
    mapping(uint => IdentityDetails) public identities;

    // Events
    event IdentityCreated(uint indexed identityId, string name, Metadata metadata, address attestationAddr);
    event IdentityNameUpdated(uint indexed identityId, string name);
    event IdentityMetadataUpdated(uint indexed identityId, Metadata metadata);

    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    function createIdentity(
        string memory name,
        Metadata memory metadata,
        address[] memory _owners,
        address[] memory _members
    ) external returns (uint256) {

        IdentityDetails memory identityDetails = IdentityDetails(
            name,
            metadata,
            _generateAttestationAddr(identityId, name)
        );

        identities[identityId] = identityDetails;

        // generate roles
        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(identityId, RoleType.MEMBER);

        // assign roles
        for(uint i = 0; i < _owners.length; i++) {
            _grantRole(ownerRole, _owners[i]);
        }
        for(uint i = 0; i < _members.length; i++) {
            _grantRole(memberRole, _members[i]);
        }

        emit IdentityCreated(identityId, name, metadata, identityDetails.attestationAddr);

        identityId++;
        
        return identityId;
    }

    /// @notice Updates the name of the identity. 
    /// @param _identityId The identityId of the identity
    /// @param _name The new name of the identity
    /// @dev Only owner can update the name. Also updated the attestation address
    function updateIdentityName(uint _identityId, string memory _name) external {

        bytes32 ownerRole = _generateRole(identityId, RoleType.OWNER);

        if (!hasRole(ownerRole, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        identities[_identityId].name = _name;
        identities[_identityId].attestationAddr = _generateAttestationAddr(_identityId, _name);

        emit IdentityNameUpdated(_identityId, _name);
    }

    // @todo override changing owners (core owner, not contributors) to make sure it updates attestation address

    /// @notice update the metadata of the identity
    /// @param _identityId The identityId of the identity
    /// @param _metadata The new metadata of the identity
    /// @dev Only owner or member can update metadata
    function updateIdentityMetadata(uint _identityId, Metadata memory _metadata) external {

        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);

        if (
            !hasRole(ownerRole, msg.sender) ||
            !hasRole(memberRole, msg.sender)
        ) {
            revert NO_ACCESS_TO_ROLE();
        }

        identities[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner of the identity
    function isOwnerOfIdentity(uint _identityId, address _owner) external view returns (bool) {
        bytes32 ownerRole = _generateRole(_identityId, RoleType.OWNER);
        return hasRole(ownerRole, _owner);
    }


    /// @notice Returns if the given address is an member of the identity
    function isMemberOfIdentity(uint _identityId, address _owner) external view returns (bool) {
        bytes32 memberRole = _generateRole(_identityId, RoleType.MEMBER);
        return hasRole(memberRole, _owner);
    }

    /// @notice Generates the attestation address for the given identity
    function _generateAttestationAddr(uint _identityId, string memory _name) internal pure returns (address) {
        bytes32 attestationHash = keccak256(
            abi.encodePacked(_identityId, _name)
        );

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the OZ role for an given identity
    function _generateRole(uint _identityId, RoleType _roleType) internal pure returns (bytes32 roleHash) {
        roleHash = keccak256(
            abi.encodePacked(_identityId, _roleType)
        );
    }
}