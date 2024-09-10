// SPDX-License-Identifier: GPL
pragma solidity ^0.8.19;

/**
 * @title IGitcoinPassportDecoder
 * @notice Minimal interface for consuming GitcoinPassportDecoder data
 */
interface IGitcoinPassportDecoder {
    /**
     * @dev A struct storing a passport credential
     */
    struct Credential {
        string provider;
        bytes32 hash;
        uint64 time;
        uint64 expirationTime;
    }

    function getPassport(address user) external returns (Credential[] memory);

    function getScore(address user) external view returns (uint256);

    function isHuman(address user) external view returns (bool);
}
