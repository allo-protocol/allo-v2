// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

library Metadata {
    struct MetaPtr {
        /// @notice Protocol ID corresponding to a specific protocol.
        /// More info at https://github.com/allo-protocol/contracts/tree/main/docs/MetaPtrProtocol.md
        uint256 protocol;
        /// @notice Pointer to fetch metadata for the specified protocol
        string pointer;
    }
}
