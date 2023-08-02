// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title Clone library
/// @notice A library to create clones of the strategy contracts when a pool is created
library Clone {
    /// @notice Custom errors
    error NOT_CONTRACT();

    /// @notice Create a clone of the contract
    /// @param _contract The address of the contract to clone
    /// @param _nonce The nonce to use for the clone
    function createClone(address _contract, uint256 _nonce) internal returns (address) {
        if (!_isContract(_contract)) {
            revert NOT_CONTRACT();
        }
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _nonce));
        return ClonesUpgradeable.cloneDeterministic(_contract, salt);
    }

    /// @notice Checks if the address is a contract
    /// @param _address The address to check
    function _isContract(address _address) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }
        return codeSize > 0;
    }
}
