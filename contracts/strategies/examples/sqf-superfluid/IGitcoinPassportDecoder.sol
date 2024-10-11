// SPDX-License-Identifier: GPL
pragma solidity ^0.8.19;

/// @title IGitcoinPassportDecoder
/// @notice Minimal interface for consuming GitcoinPassportDecoder data
interface IGitcoinPassportDecoder {
    /// @dev A struct storing a passport credential
    /// @param provider The provider of the credential
    /// @param hash The hash of the credential
    /// @param time The time the credential was issued
    /// @param expirationTime The time the credential expires
    struct Credential {
        string provider;
        bytes32 hash;
        uint64 time;
        uint64 expirationTime;
    }

    /// @dev Returns the passport credentials for a user
    /// @param user The user's address
    /// @return The user's passport credentials
    function getPassport(address user) external returns (Credential[] memory);

    /// @dev Returns the user's score
    /// @param user The user's address
    /// @return The user's score
    function getScore(address user) external view returns (uint256);

    /// @dev Returns TRUE if the user is a human
    /// @param user The user's address
    /// @return The boolean indicating if the user is a human
    function isHuman(address user) external view returns (bool);
}
