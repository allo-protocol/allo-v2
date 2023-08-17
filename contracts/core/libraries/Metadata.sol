// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Metadata struct
/// @dev This is used to define the metadata for the protocol that is used throughout the system
struct Metadata {
    /// @notice Protocol ID corresponding to a specific protocol (currently using IPFS = 1)
    uint256 protocol;
    /// @notice Pointer (hash) to fetch metadata for the specified protocol
    string pointer;
}
