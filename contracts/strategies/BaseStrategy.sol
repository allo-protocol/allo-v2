// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {IStrategy} from "./IStrategy.sol";
import {Transfer} from "../core/libraries/Transfer.sol";

abstract contract BaseStrategy is IStrategy, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    Allo public immutable allo;
    uint256 public poolId;
    bytes32 public identityId;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @param _allo Address of the Allo contract
    constructor(address _allo) {
        allo = Allo(_allo);
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if the caller is the Allo contract
    modifier onlyAllo() {
        if (msg.sender != address(allo)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the caller is a pool manager
    modifier onlyPoolManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by Allo.sol
    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external virtual onlyAllo {
        require(_identityId != bytes32(0), "invalid identity id");
        require(identityId == bytes32(0), "already initialized");

        identityId = _identityId;
        poolId = _poolId;
    }

    function skim(address _token) external virtual override {
        (,, address token, uint256 amount,,,) = allo.pools(poolId);
        uint256 fundedBalance;
        if (token == _token) {
            fundedBalance = amount;
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > fundedBalance) {
            uint256 excessFunds = balance - fundedBalance;
            uint256 bounty = (excessFunds * allo.feeSkirtingBounty()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            _transferAmount(_token, allo.treasury(), excessFunds);
            _transferAmount(_token, msg.sender, bounty);
            emit Skim(msg.sender, _token, excessFunds, bounty);
        }
    }
}
