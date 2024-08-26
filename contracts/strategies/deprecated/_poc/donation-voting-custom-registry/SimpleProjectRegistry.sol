// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/**
 * Simple Project Registry
 *
 * This contract is a very minimal implementation of a registry, intended for
 * testing and demonstration. Allo provides a robust Project Registry that
 * strategies can use. But strategies can use any means of validating projects
 * (whether they are on the Allo Registry or not).
 *
 * This contract assumes an owner, like a DAO, with explicit permission to add
 * and remove projects from the registry. The allocation strategy that
 * accompanies simply check whether or not a project is listed on this
 * registry.
 */
import "solady/auth/Ownable.sol";

/// @title Simple Project Registry
/// @author @0xZakk <zakk@gitcoin.co>
/// @notice This contract is a simple implementation of a registry. It is
/// intended to show that strategies can leverage their own registries. It assumes
/// an owner, like a DAO, with explicit permission to add and remove projects from
/// the registry.
contract SimpleProjectRegistry is Ownable {
    //===========================
    //====== Variables ==========
    //===========================

    /// @notice The projects in the registry
    mapping(address => bool) public projects;

    //===========================
    //========= Events ==========
    //===========================

    /// @notice Emitted when a project is added to the Registry
    /// @param project The project that was added
    event ProjectAdded(address indexed project);

    /// @notice Emitted when a project is removed from the Registry
    /// @param project The project that was removed
    event ProjectRemoved(address indexed project);

    //===========================
    //========= Errors =========
    //===========================

    /// @notice Error when a project is already in the registry
    error ALREADY_EXISTS();
    error DOESNT_EXIST();

    //===========================
    //===== Constructor =========
    //===========================

    constructor(address _initialOwner) {
        _initializeOwner(_initialOwner);
    }

    //===========================
    //========= Methods =========
    //===========================

    /// @notice Add a project to the registry
    /// @param _project The project to add
    function addProject(address _project) external onlyOwner {
        _addProject(_project);
    }

    /// @notice Add an array projects to the registry
    /// @param _projects The projects to add
    function addProjects(address[] calldata _projects) external onlyOwner {
        for (uint256 i; i < _projects.length; i++) {
            _addProject(_projects[i]);
        }
    }

    /// @notice Remove a project from the registry
    /// @param _project The project to remove
    function removeProject(address _project) external onlyOwner {
        _removeProject(_project);
    }

    /// @notice Remove an array of projects from the registry
    /// @param _projects The projects to remove
    function removeProjects(address[] calldata _projects) external onlyOwner {
        for (uint256 i; i < _projects.length; i++) {
            _removeProject(_projects[i]);
        }
    }

    //===========================
    //==== Internal Methods =====
    //===========================

    /// @notice Internal method that adds projects to the registry
    /// @param _project The address of the project to add
    function _addProject(address _project) internal {
        if (projects[_project]) {
            revert ALREADY_EXISTS();
        }
        projects[_project] = true;

        emit ProjectAdded(_project);
    }

    /// @notice Internal method that removes a project from the registry
    /// @param _project The address of the project to remove
    function _removeProject(address _project) internal {
        if (!projects[_project]) {
            revert DOESNT_EXIST();
        }
        projects[_project] = false;

        emit ProjectRemoved(_project);
    }
}
