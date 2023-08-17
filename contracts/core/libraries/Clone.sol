// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title Clone library
/// @notice A helper library to create deterministic clones of the strategy contracts when a pool is created
/// @dev Handles the creation of clones for the strategy contracts and returns the address of the clone
library Clone {
    /// @dev Create a clone of the contract
    /// @param _contract The address of the contract to clone
    /// @param _nonce The nonce to use for the clone
    function createClone(address _contract, uint256 _nonce) internal returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _nonce));
        return ClonesUpgradeable.cloneDeterministic(_contract, salt);
    }
}
