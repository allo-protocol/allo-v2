// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Imports
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Internal Imports
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";

/// @title NFT Gating Extension
/// @notice This contract is providing nft gating options for a strategy's calls
/// @dev This contract is inheriting BaseStrategy
abstract contract NFTGatingExtension is BaseStrategy {
    /// ================================
    /// ========== Errors ==============
    /// ================================
    /// @notice Throws when the token is zero address
    error NFTGatingExtension_INVALID_TOKEN();
    /// @notice Throws when the actor is zero address
    error NFTGatingExtension_INVALID_ACTOR();
    /// @notice Throws when the balance of the actor is insufficient
    error NFTGatingExtension_INSUFFICIENT_BALANCE();

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// @notice This modifier checks if the actor holds a certain NFT
    /// @param _nft The NFT address
    /// @param _actor The actor address
    modifier onlyWithNFT(address _nft, address _actor) {
        _checkOnlyWithNFT(_nft, _actor);
        _;
    }

    /// ===============================
    /// ======= Internal Functions ====
    /// ===============================

    /// @notice This function checks if the actor has a certain NFT
    /// @param _nft The NFT address
    /// @param _actor The actor address
    function _checkOnlyWithNFT(address _nft, address _actor) internal view virtual {
        if (_nft == address(0)) revert NFTGatingExtension_INVALID_TOKEN();
        if (_actor == address(0)) revert NFTGatingExtension_INVALID_ACTOR();
        if (IERC721(_nft).balanceOf(_actor) == 0) revert NFTGatingExtension_INSUFFICIENT_BALANCE();
    }
}
