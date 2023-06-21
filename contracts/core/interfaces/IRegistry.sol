// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "../../core/libraries/Metadata.sol";

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
interface IRegistry {
    struct IdentityDetails {
        uint id;
        string name;
        Metadata.MetaPtr metadata;
        address attestationAddress;
    }

    // getter for identities mapping
    function getIdentity(uint _identityId) external view returns (IdentityDetails memory);

    // create a new project with metadata
    // set identityId using an incrementer
    // attestationAddr = addr(hash(id, name)) => this confirms that neither can change while keepign address the same
    // @todo think about whether there's any value to deploying an address using CREATE2, we think not
    function createIdentity(
        IdentityDetails memory _identityDetails,
        address[] memory _owners
    ) external returns (uint256);

    // updates the name of the identity
    // note that this will also change the attestation address, since it's a hash that includes the name
    function updateIdentityName(
        uint _identityId,
        string memory _name
    ) external;

    // @todo override changing owners (core owner, not contributors) to make sure it updates attestation address

    // update the metadata of the identity
    // checks ownership role first, probably separate roles for this vs using it (owner vs user?)
    function updateIdentityMetadata(uint _identityId, string memory _metadata) external;

    // this will use solmate ROLES to check if the msg.sender is an owner of the identity
    // @todo figure out how to best represent identity ownership and details
    function isOwnerOfIdentity(
        uint _identityId,
        address _owner
    ) external view returns (bool);
}
