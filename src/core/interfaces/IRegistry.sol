// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "../../core/libraries/Metadata.sol";

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
interface IRegistry {
    // getter for identities mapping
    function getIdentities(
        address _identityId
    ) external view returns (Metadata.IdentityDetails memory);

    // create a new project with metadata
    // sets roles so that all owners are owners of the project
    function createIdentity(
        Metadata.IdentityDetails memory _identityDetails,
        address[] memory _owners
    ) external returns (uint256);

    // updates the name of the identity
    // note that this will also change the attestation address, since it's a hash that includes the name
    function updateIdentityName(
        address _identityId,
        string memory _name
    ) external;

    // this will use solmate ROLES to check if the msg.sender is an owner of the identity
    // @todo figure out how to best represent identity ownership and details
    // @todo should identityId be bytes hash vs uint256?
    function isOwnerOfIdentity(
        address _identityId,
        address _owner
    ) external view returns (bool);
}
