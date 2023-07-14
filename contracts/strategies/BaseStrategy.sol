// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Allo} from "../core/Allo.sol";
import {IStrategy} from "./IStrategy.sol";
import {Transfer} from "../core/libraries/Transfer.sol";

abstract contract BaseStrategy is IStrategy, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    Allo private immutable allo;
    uint256 private poolId;
    string private strategyName;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @param _allo Address of the Allo contract
    constructor(address _allo, string memory _name) {
        allo = Allo(_allo);
        strategyName = _name;
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

    /// ================================
    /// =========== Views ==============
    /// ================================

    function getAllo() external view override returns (Allo) {
        return allo;
    }

    function getPoolId() external view override returns (uint256) {
        return poolId;
    }

    function getStrategyName() external view override returns (string memory) {
        return strategyName;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by Allo.sol
    function initialize(uint256 _poolId, bytes memory _data) external virtual onlyAllo {
        if (_poolId == 0) {
            revert BaseStrategy_INVALID_ADDRESS();
        }
        if (poolId != 0) {
            revert BaseStrategy_STRATEGY_ALREADY_INITIALIZED();
        }
        poolId = _poolId;
    }

    function skim(address _token) external virtual override {
        (,, address token, uint256 amount,,,) = allo.pools(poolId);
        uint256 balanceCapturedInPool = (token == _token) ? amount : 0;

        uint256 balanceInStrategy =
            _token == address(0) ? address(this).balance : IERC20(_token).balanceOf(address(this));

        if (balanceInStrategy > balanceCapturedInPool) {
            uint256 excessFunds = balanceInStrategy - balanceCapturedInPool;
            uint256 bounty = (excessFunds * allo.feeSkirtingBountyPercentage()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            _transferAmount(_token, allo.treasury(), excessFunds);
            _transferAmount(_token, msg.sender, bounty);
            emit Skim(msg.sender, _token, excessFunds, bounty);
        }
    }
}
