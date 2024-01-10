// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "./libraries/Metadata.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

contract BulkCreation {
    mapping(bytes32 => bytes32) public projectIdToProfileId;

    constructor() {}

    function createProfiles(address registry, bytes memory encodedData) external returns (bytes memory) {
        (
            bytes32[] memory projectId,
            uint256[] memory _nonce,
            string[] memory _name,
            Metadata[] memory _metadata,
            address[] memory _owner
        ) = abi.decode(encodedData, (bytes32[], uint256[], string[], Metadata[], address[]));

        uint256 _profilesLength = _nonce.length;

        bytes32[] memory migratedProfileIds = new bytes32[](_profilesLength);

        for (uint256 i = 0; i < _profilesLength;) {
            bytes32 profileId =
                IRegistry(registry).createProfile(_nonce[i], _name[i], _metadata[i], _owner[i], new address[](0));

            projectIdToProfileId[projectId[i]] = profileId;

            migratedProfileIds[i] = profileId;

            unchecked {
                i++;
            }
        }

        return abi.encode(migratedProfileIds);
    }
}
