// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { MetaPtr } from "../utils/MetaPtr.sol";

// use Solady Roles for ownership of projects: https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol
interface IRegistry {
    struct ProjectDetails {
        MetaPtr metadata;
    }

    // getter for projects mapping
    function projects(uint256 _projectId) external view returns (ProjectDetails memory);

    // create a new project with metadata
    // sets roles so that all owners are owners of the project
    function createProject(ProjectDetails memory _projectDetails, address[] memory _owners) external returns (uint256);

    // this will use solmate ROLES to check if the msg.sender is an owner of the project
    // @todo figure out how to best represent project ownership and details
    // @todo should projectId be bytes hash vs uint256?
    function isOwnerOfProject(uint256 _projectId, address _owner) external view returns (bool);
}