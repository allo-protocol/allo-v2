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
        bytes memory encodedData = abi.encode(_profileId, _name);
        bytes memory encodedConstructor = abi.encode(_profileId, address(_registry));

        bytes memory bytecode = abi.encodePacked(type(Anchor).creationCode, encodedConstructor);

        bytes32 salt = keccak256(encodedData);

        address preComputedAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(_registry), salt, keccak256(bytecode)))))
        );

        return preComputedAddress;
    }

    /// @notice Generates the profileId based on msg.sender
    /// @param _nonce Nonce used to generate profileId
    function _testUtilGenerateProfileId(uint256 _nonce, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, sender));
    }
}
