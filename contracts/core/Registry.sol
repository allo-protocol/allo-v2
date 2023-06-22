// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OwnableRoles } from "../../lib/solady/src/auth/OwnableRoles.sol";
import { Metadata } from "./libraries/Metadata.sol";

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
contract Registry is OwnableRoles {

    // ASK: should this be renamed to identityIndex ?
    uint private identityId;

    struct IdentityDetails {
        string name;
        Metadata metadata;
        address attestationAddr;
        // address coreOwner; // ASK: Should this be added?
    }

    /// @notice identityId -> IdentityDetails
    mapping(uint => IdentityDetails) public identities;

    // Events
    event IdentityCreated(uint indexed identityId, string name, Metadata metadata, address attestationAddr);
    event IdentityNameUpdated(uint indexed identityId, string name);
    event IdentityMetadataUpdated(uint indexed identityId, Metadata metadata);

    // ASK: Is this needed if we have the mapping as public?
    // // getter for projects mapping
    // function identities(uint _identityId) external view returns (IdentityDetails memory) {

    // }

    // create a new project with metadata
    // hash some unique value to create the identityId - is there enough immutable to do this or just use incrementer?
    // @todo if owners were immutable, we could make it a merkle proof of addresses and prove ownership that way? probably overkill
    // sets roles so that all owners are owners of the project
    // attestationAddr = addr(hash(id, name, owner))
    // OR deploy right away with CREATE2 as proxy so they can do anything (or just forward ERC20s and ETH)
    // id => IdentityDetails

    // ASK: changing the function signature as attestationAddr has to be generated from the name and caller
    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    function createIdentity(
        string memory name,
        Metadata memory metadata,
        address[] memory _owners
    ) external returns (uint256) {

        IdentityDetails memory identityDetails = IdentityDetails(
            name,
            metadata,
            // ASK : should identityId be used as the hash for attestationAddr?
            // cause project can't have same attestAddr across chains
            generateAttestationAddr(name, msg.sender)
        );

        identities[identityId] = identityDetails;

        for(uint i = 0; i < _owners.length; i++) {
            _grantRoles(_owners[i], identityId);
        }
        
        emit IdentityCreated(identityId, name, metadata, identityDetails.attestationAddr);

        identityId++;
        
        return identityId;
    }

    /// @notice Updates the name of the identity
    /// @dev This will also change the attestation address, since it's a hash that includes the name
    // ASK: should only coreOwner be able to change name?
    function updateIdentityName(uint _identityId, string memory _name) onlyRoles(identityId) external {
        identities[_identityId].name = _name;
        // ASK: this has to be core owner and not msg.sender
        identities[_identityId].attestationAddr = generateAttestationAddr(_name, msg.sender);

        emit IdentityNameUpdated(_identityId, _name);
    }

    function changeCoreOwner(uint _identityId, address _newCoreOwner) external {
        // ASK -> the actual owner cannot be tracked by Solady ROLES. 
        // Would this be stored on IdentityDetails ?

        // @todo check if msg sender is owner
        // @todo check if new owner is not already owner
        // @todo regenrate attestation address 
        // @todo change owner
    }

    // @todo override changing owners (core owner, not contributors) to make sure it updates attestation address

    // update the metadata of the identity
    // checks ownership role first, probably separate roles for this vs using it (owner vs user?)
    function updateIdentityMetadata(uint _identityId, Metadata memory _metadata) onlyRoles(identityId) external {
        identities[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner of the project
    function isOwnerOfIdentity(uint _identityId, address _owner) external view returns (bool) {
        return hasAnyRole(_owner, _identityId);
    }

    /// @notice Generates the attestation address for the given identity
    function generateAttestationAddr(string memory _name, address _owner) internal pure returns (address) {
        bytes32 attestationHash = keccak256(
            abi.encodePacked(_name, _owner)
        );

        return address(uint160(uint256(attestationHash)));
    }
}