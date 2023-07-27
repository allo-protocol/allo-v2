// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";

// Mock Registry contract
contract MockRegistry {
    mapping(bytes32 => address) public owners;

    function isOwnerOfIdentity(bytes32 identityId, address owner) external view returns (bool) {
        return owners[identityId] == owner;
    }

    function setOwnerOfIdentity(bytes32 identityId, address owner) external {
        owners[identityId] = owner;
    }
}

contract AnchorTest is Test {
    Anchor public anchor;
    MockRegistry public mockRegistry;

    function setUp() public {
        mockRegistry = new MockRegistry();
        anchor = new Anchor(address(mockRegistry));
    }

    function test_deploy() public {
        anchor = new Anchor(address(mockRegistry));
    }

    function test_initialize() public {
        bytes32 identityId = bytes32("test_identity");

        // Only the registry contract should be able to initialize the anchor
        assertTrue(anchor.identityId() == bytes32(0)); // Check if identityId is not initialized yet

        mockRegistry.setOwnerOfIdentity(identityId, address(this)); // Set the caller as the owner of the identity

        vm.prank(address(mockRegistry)); // Prank the registry contract to make it think it's the caller
        anchor.initialize(identityId); // Initialize the anchor
        assertTrue(anchor.identityId() == identityId); // Check if identityId is set after initialization
    }

    function testRevert_initialize_UNAUTHORIZED() public {
        bytes32 identityId = bytes32("test_identity");

        vm.expectRevert(Anchor.UNAUTHORIZED.selector); // Expect a revert with the UNAUTHORIZED error
        anchor.initialize(identityId); // Try to initialize the anchor from an unauthorized address
    }

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        bytes32 identityId = bytes32("test_identity");

        // Only the registry contract should be able to initialize the anchor
        assertTrue(anchor.identityId() == bytes32(0)); // Check if identityId is not initialized yet
        mockRegistry.setOwnerOfIdentity(identityId, address(this)); // Set the caller as the owner of the identity

        vm.prank(address(mockRegistry)); // Prank the registry contract to make it think it's the caller
        anchor.initialize(identityId); // Initialize the anchor
        assertTrue(anchor.identityId() == identityId); // Check if identityId is set after initialization

        vm.expectRevert(Anchor.ALREADY_INITIALIZED.selector); // Expect a revert with the ALREADY_INITIALIZED error

        // Try to initialize the anchor again with a different identityId (should revert)
        vm.prank(address(mockRegistry)); // Prank the registry contract to make it think it's the caller
        bytes32 identityId2 = bytes32("test_identity_2");
        anchor.initialize(identityId2);
    }

    function test_execute() public {
        vm.prank(address(mockRegistry)); // Prank the registry contract to make it think it's the caller
        bytes32 identityId = bytes32("test_identity");
        anchor.initialize(identityId);

        mockRegistry.setOwnerOfIdentity(identityId, address(this)); // Set the caller as the owner of the identity

        // Deploy a simple contract that increments a value and return it
        Incrementer incrementer = new Incrementer();
        uint256 initialValue = incrementer.getValue();

        // Execute a call to increment the value by 10
        bytes memory data = abi.encodeWithSignature("increment(uint256)", 10);
        anchor.execute(address(incrementer), 0, data);

        // Check if the value has been incremented
        uint256 finalValue = incrementer.getValue();
        assertTrue(finalValue == initialValue + 10);
    }

    function test_execute_UNAUTHORIZED() public {
        // Deploy a simple contract that increments a value and return it
        Incrementer incrementer = new Incrementer();

        vm.expectRevert(Anchor.UNAUTHORIZED.selector); // Expect a revert with the UNAUTHORIZED error

        // Execute a call to increment the value by 10 from an unauthorized address (should revert)
        bytes memory data = abi.encodeWithSignature("increment(uint256)", 10);
        anchor.execute(address(incrementer), 0, data);
    }

    function test_execute_CALL_FAILED() public {
        vm.prank(address(mockRegistry)); // Prank the registry contract to make it think it's the caller
        bytes32 identityId = bytes32("test_identity");
        anchor.initialize(identityId);

        mockRegistry.setOwnerOfIdentity(identityId, address(this)); // Set the caller as the owner of the identity
        // Deploy a contract without a fallback function (cannot receive ETH)
        NoFallbackContract noFallback = new NoFallbackContract();

        vm.expectRevert(Anchor.CALL_FAILED.selector); // Expect a revert with the CALL_FAILED error
        // Try to execute a call to the contract (should revert because the call will fail)
        bytes memory data = abi.encodeWithSignature("someFunction()");
        anchor.execute(address(noFallback), 1 ether, data);
    }
}

// Simple contract with a single function to increment a value
contract Incrementer {
    uint256 public value;

    function increment(uint256 amount) external {
        value += amount;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

// Simple contract without a fallback function (cannot receive ETH)
contract NoFallbackContract {
// This contract intentionally does not have a fallback function
}
