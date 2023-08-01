// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
library TestUtilities {
    /// @notice Generates the anchor for the given profileId and name
    /// @param _profileId Id of the profile
    /// @param _name The name of the profile
    function _testUtilGenerateAnchor(bytes32 _profileId, string memory _name, address _registry)
        internal
        pure
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(_profileId, _name));

        return getDeployed(salt, _registry);
    }

    /// @notice Generates the profileId based on msg.sender
    /// @param _nonce Nonce used to generate profileId
    function _testUtilGenerateProfileId(uint256 _nonce, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, sender));
    }

    /// @dev Returns the deterministic address for `salt`.
    function getDeployed(bytes32 salt, address registry) internal pure returns (address deployed) {
        /// @dev Hash of the `_PROXY_BYTECODE`.
        /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
        bytes32 _PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, registry)
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }
}
