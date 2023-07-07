// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

library TestUtilities {
    /// @notice Generates the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _testUtilGenerateAnchor(bytes32 _identityId, string memory _name) internal pure returns (address) {
        bytes32 attestationHash = keccak256(abi.encodePacked(_identityId, _name));

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the identityId based on msg.sender
    /// @param _nonce Nonce used to generate identityId
    function _testUtilGenerateIdentityId(uint256 _nonce, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, sender));
    }
}
