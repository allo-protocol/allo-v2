// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { MetaPtr } from "../../utils/MetaPtr.sol";

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
interface IRegistry {
    struct IdentityDetails {
        MetaPtr metadata;
    }

    // getter for identities mapping
    function identities(uint256 _projectId) external view returns (IdentityDetails memory);

    // create a new project with metadata
    // sets roles so that all owners are owners of the project
    function createIdentity(IdentityDetails memory _identityDetails, address[] memory _owners) external returns (uint256);

    // this will use solmate ROLES to check if the msg.sender is an owner of the identity
    // @todo figure out how to best represent identity ownership and details
    // @todo should identityId be bytes hash vs uint256?
    function isOwnerOfIdentity(uint256 _identityId, address _owner) external view returns (bool);
}