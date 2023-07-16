// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IStrategy.sol";

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Transfer} from "../core/libraries/Transfer.sol";

abstract contract BaseStrategy is IStrategy, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    IAllo internal immutable allo;
    uint256 internal poolId;
    bytes32 internal strategyId;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @param _allo Address of the Allo contract
    constructor(address _allo, string memory _name) {
        allo = IAllo(_allo);
        strategyId = keccak256(abi.encode(_name));
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

    function getAllo() external view override returns (IAllo) {
        return allo;
    }

    function getPoolId() external view override returns (uint256) {
        return poolId;
    }

    function getStrategyId() external view override returns (bytes32) {
        return strategyId;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by Allo.sol
    function initialize(uint256 _poolId, bytes memory _data) public virtual onlyAllo {
        if (_poolId == 0) {
            revert BaseStrategy_INVALID_ADDRESS();
        }
        if (poolId != 0) {
            revert BaseStrategy_STRATEGY_ALREADY_INITIALIZED();
        }
        poolId = _poolId;
        _data; // Silence unused parameter warning: _data
    }

    function skim(address _token) external virtual override {
        IAllo.Pool memory pool = allo.getPool(poolId);
        uint256 balanceCapturedInPool = (pool.token == _token) ? pool.amount : 0;

        uint256 balanceInStrategy =
            _token == address(0) ? address(this).balance : IERC20(_token).balanceOf(address(this));

        if (balanceInStrategy > balanceCapturedInPool) {
            uint256 excessFunds = balanceInStrategy - balanceCapturedInPool;
            uint256 bounty = (excessFunds * allo.getFeeSkirtingBountyPercentage()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            _transferAmount(_token, allo.getTreasury(), excessFunds);
            _transferAmount(_token, msg.sender, bounty);
            emit Skim(msg.sender, _token, excessFunds, bounty);
        }
    }
}
