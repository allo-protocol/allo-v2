// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
contract Registry {
    struct IdentityDetails {
        string name;
        string metadata; // @todo update to MetaPtr
        address attestationAddr;
    }

    // getter for projects mapping
    function identities(uint _identityId) external view returns (IdentityDetails memory) {

    }

    // create a new project with metadata
    // hash some unique value to create the identityId - is there enough immutable to do this or just use incrementer?
    // @todo if owners were immutable, we could make it a merkle proof of addresses and prove ownership that way? probably overkill
    // sets roles so that all owners are owners of the project
    // attestationAddr = addr(hash(id, name, owner))
    // OR deploy right away with CREATE2 as proxy so they can do anything (or just forward ERC20s and ETH)
    // id => IdentityDetails
    function createIdentity(IdentityDetails memory _identityDetails, address[] memory _owners) external returns (uint256) {

    }

    // updates the name of the identity
    // note that this will also change the attestation address, since it's a hash that includes the name
    function updateIdentityName(uint _identityId, string memory _name) external {

    }

    // @todo override changing owners (core owner, not contributors) to make sure it updates attestation address

    // update the metadata of the identity
    // checks ownership role first, probably separate roles for this vs using it (owner vs user?)
    function updateIdentityMetadata(uint _identityId, string memory _metadata) external {

    }

    // this will use solmate ROLES to check if the msg.sender is an owner of the project
    // @todo figure out how to best represent project ownership and details
    function isOwnerOfProject(uint _identityId, address _owner) external view returns (bool) {
        
    }
}