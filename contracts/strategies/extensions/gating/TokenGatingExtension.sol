// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Internal Imports
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";

/// @title Token Gating Extension
/// @notice This contract is providing erc20 gating options
/// @dev This contract is inheriting BaseStrategy
abstract contract TokenGatingExtension is BaseStrategy {
    /// ================================
    /// ========== Errors ==============
    /// ================================
    /// @notice Throws when the token is zero address
    error TokenGatingExtension_INVALID_TOKEN();
    /// @notice Throws when the actor is zero address
    error TokenGatingExtension_INVALID_ACTOR();
    /// @notice Throws when the balance of the actor is insufficient
    error TokenGatingExtension_INSUFFICIENT_BALANCE();

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// @notice This modifier checks if the actor hold a certain amount of tokens
    /// @param _token The token address
    /// @param _amount The amount of tokens
    /// @param _actor The actor address
    modifier onlyWithToken(address _token, uint256 _amount, address _actor) {
        _checkOnlyWithToken(_token, _amount, _actor);
        _;
    }

    /// ===============================
    /// ======= Internal Functions ====
    /// ===============================

    /// @notice This function checks if the actor has a certain amount of tokens
    /// @param _token The token address
    /// @param _amount The amount of tokens
    /// @param _actor The actor address
    function _checkOnlyWithToken(address _token, uint256 _amount, address _actor) internal view virtual {
        if (_token == address(0)) revert TokenGatingExtension_INVALID_TOKEN();
        if (_actor == address(0)) revert TokenGatingExtension_INVALID_ACTOR();
        if (IERC20(_token).balanceOf(_actor) < _amount) revert TokenGatingExtension_INSUFFICIENT_BALANCE();
    }
}
