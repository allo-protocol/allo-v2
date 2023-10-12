// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
import {Anchor} from "../../contracts/core/Anchor.sol";

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

        return getDeployed(salt, _profileId, _registry);
    }

    /// @notice Generates the profileId based on msg.sender
    /// @param _nonce Nonce used to generate profileId
    function _testUtilGenerateProfileId(uint256 _nonce, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, sender));
    }

    /// @dev Returns the deterministic address for `salt`.
    function getDeployed(bytes32 salt, bytes32 profileId, address registry) internal pure returns (address) {
       bytes memory bytecode = abi.encodePacked(type(Anchor).creationCode, abi.encode(profileId, registry));
       return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), registry, salt, keccak256(bytecode)))))
        );
    }
}
