// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
// Mock Registry contract

contract MockRegistry {
    mapping(bytes32 => address) public owners;

    function isOwnerOfProfile(bytes32 profileId, address owner) external view returns (bool) {
        return owners[profileId] == owner;
    }

    function setOwnerOfProfile(bytes32 profileId, address owner) external {
        owners[profileId] = owner;
    }
}

contract AnchorTest is Test {
    Anchor public anchor;
    MockRegistry public mockRegistry;
    bytes32 profileId;

    function setUp() public {
        profileId = bytes32("test_profile");
        mockRegistry = new MockRegistry();
        vm.prank(address(mockRegistry));
        anchor = new Anchor(profileId, address(mockRegistry));
    }

    function test_deploy() public {
        assertEq(anchor.profileId(), bytes32("test_profile"));
        assertEq(address(anchor.registry()), address(mockRegistry));
    }

    function test_erc721Holder() public {
        bytes4 retval = anchor.onERC721Received(address(1), address(2), 1, "");
        assertEq(retval, IERC721Receiver.onERC721Received.selector);
    }

    function test_erc1155Holder() public {
        bytes4 retval = anchor.onERC1155Received(address(1), address(2), 1, 2, "");
        assertEq(retval, IERC1155Receiver.onERC1155Received.selector);
    }

    function test_erc1155HolderBatch() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 2;

        bytes4 retval = anchor.onERC1155BatchReceived(address(1), address(2), ids, values, "");
        assertEq(retval, IERC1155Receiver.onERC1155BatchReceived.selector);
    }

    function test_execute() public {
        mockRegistry.setOwnerOfProfile(profileId, address(this)); // Set the caller as the owner of the profile

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

    function test_execute_CALL_FAILED_zeroAddress() public {
        mockRegistry.setOwnerOfProfile(profileId, address(this)); // Set the caller as the owner of the profile
        vm.expectRevert(Anchor.CALL_FAILED.selector); // Expect a revert with the CALL_FAILED error
        // Try to execute a call to the contract (should revert because the call will fail)
        bytes memory data = abi.encodeWithSignature("increment(uint256)", 10);
        anchor.execute(address(0), 1 ether, data);
    }

    function test_execute_CALL_FAILED() public {
        mockRegistry.setOwnerOfProfile(profileId, address(this)); // Set the caller as the owner of the profile
        // Deploy a contract without a fallback function (cannot receive ETH)
        NoFallbackContract noFallback = new NoFallbackContract();

        vm.expectRevert(Anchor.CALL_FAILED.selector); // Expect a revert with the CALL_FAILED error
        // Try to execute a call to the contract (should revert because the call will fail)
        bytes memory data = abi.encodeWithSignature("someFunction()");
        anchor.execute(address(noFallback), 1 ether, data);
    }

    function test_sendETH() public {
        mockRegistry.setOwnerOfProfile(profileId, address(this)); // Set the caller as the owner of the profile

        vm.deal(address(anchor), 1 ether); // Send 1 ETH to the Anchor contract
        assertEq(address(anchor).balance, 1 ether); // Check if the balance of the contract has been updated

        address target = makeAddr("randomReceiver");
        anchor.execute(target, 1 ether, ""); // Execute a call to send 1 ETH to the target address

        assertEq(address(anchor).balance, 0); // Check if the balance of the contract has been updated
        assertEq(address(target).balance, 1 ether); // Check if the balance of the target address has been updated
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
