// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Strategy Contracts
import {SimpleProjectRegistry} from
    "../../../contracts/strategies/_poc/donation-voting-custom-registry/SimpleProjectRegistry.sol";
// Test Libraries
import {Accounts} from "../shared/Accounts.sol";

contract SimpleProjectRegistryStrategyTest is Test, Accounts {
    event ProjectAdded(address indexed project);
    event ProjectRemoved(address indexed project);

    SimpleProjectRegistry simpleRegistry;

    address public project = makeAddr("project");

    function setUp() public {
        simpleRegistry = new SimpleProjectRegistry(registry_owner());
    }

    /// @notice Tests deployment of the Registry and checks the owner
    function test_Deployment() public {
        assertTrue(address(simpleRegistry) != address(0));
        assertTrue(simpleRegistry.owner() == registry_owner());
    }

    /// @notice Tests adding a project to the registry
    function test_addProject() public {
        vm.prank(registry_owner());
        vm.expectEmit(true, false, false, true);
        emit ProjectAdded(project);

        simpleRegistry.addProject(project);
        assertTrue(simpleRegistry.projects(project));
    }

    /// @notice Tests adding an array of projects to the registry
    function test_addProjects() public {
        vm.prank(registry_owner());
        vm.expectEmit(true, false, false, true);
        emit ProjectAdded(project);

        address project2 = makeAddr("project2");

        address[] memory projects = new address[](2);
        projects[0] = project;
        projects[1] = project2;

        simpleRegistry.addProjects(projects);
        assertTrue(simpleRegistry.projects(project));
        assertTrue(simpleRegistry.projects(project2));
        assertFalse(simpleRegistry.projects(randomAddress()));
    }

    /// @notice Tests that only the owner can add a project to the registry and reverts otherwise
    function testRevert_addProject_UNAUTHORIZED() public {
        vm.prank(randomAddress());
        vm.expectRevert();

        simpleRegistry.addProject(project);
    }

    /// @notice Tests adding a project to the registry when the project is already in the registry
    function testRevert_addProject_ALREADY_EXISTS() public {
        __add_project();
        vm.expectRevert(SimpleProjectRegistry.ALREADY_EXISTS.selector);

        vm.prank(registry_owner());
        simpleRegistry.addProject(project);
    }

    /// @notice Tests removing a project from the registry
    function test_removeProject() public {
        vm.startPrank(registry_owner());

        simpleRegistry.addProject(project);

        vm.expectEmit(true, false, false, true);
        emit ProjectRemoved(project);

        simpleRegistry.removeProject(project);
        vm.stopPrank();

        assertFalse(simpleRegistry.projects(project));
    }

    /// @notice Tests that only the owner can remove a project from the registry and reverts otherwise
    function testRevert_removeProject_UNAUTHORIZED() public {
        __add_project();
        vm.expectRevert();

        vm.prank(randomAddress());
        simpleRegistry.removeProject(project);
    }

    /// @notice Tests removing a project from the registry when the project doesn't exist in the registry
    function testRevert_removeProject_DOESNT_EXIST() public {
        vm.expectRevert(SimpleProjectRegistry.DOESNT_EXIST.selector);

        vm.prank(registry_owner());
        simpleRegistry.removeProject(project);
    }

    /// @notice Tests removing an array of projects to the registry
    function test_removeProjects() public {
        __add_project();
        vm.expectEmit(true, false, false, true);
        emit ProjectRemoved(project);

        address[] memory projects = new address[](1);
        projects[0] = project;

        vm.prank(registry_owner());
        simpleRegistry.removeProjects(projects);

        assertFalse(simpleRegistry.projects(project));
    }

    /// @notice Tests that only the owner can remove a project from the registry and reverts otherwise
    function testRevert_removeProjects_UNAUTHORIZED() public {
        __add_project();
        vm.expectRevert();

        address[] memory projects = new address[](1);
        projects[0] = project;

        vm.prank(randomAddress());
        simpleRegistry.removeProjects(projects);
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    /// @notice Helper function to add a project to the registry
    function __add_project() internal {
        vm.prank(registry_owner());
        simpleRegistry.addProject(project);
    }

    /// @notice Helper function to remove a project from the registry
    function __remove_project() internal {
        vm.prank(registry_owner());
        simpleRegistry.removeProject(project);
    }
}
