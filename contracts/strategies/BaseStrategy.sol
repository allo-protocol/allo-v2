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
    bool internal poolActive;

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
    modifier onlyPoolManager(address _sender) {
        if (!allo.isPoolManager(poolId, _sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the pool is active
    modifier onlyActivePool() {
        if (!poolActive) {
            revert BaseStrategy_POOL_INACTIVE();
        }
        _;
    }

    modifier onlyInitialized() {
        if (poolId == 0) {
            revert BaseStrategy_NOT_INITIALIZED();
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

    function isPoolActive() external view override returns (bool) {
        return poolActive;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _poolId Id of the pool
    /// @dev This function is called by Allo.sol
    function __BaseStrategy_init(uint256 _poolId) internal virtual {
        if (poolId != 0) {
            revert BaseStrategy_ALREADY_INITIALIZED();
        }
        poolId = _poolId;
    }

    function skim(address _token) external virtual override {
        IAllo.Pool memory pool = allo.getPool(poolId);
        uint256 balanceCapturedInPool = (pool.token == _token) ? pool.amount : 0;

        uint256 balanceInStrategy = _token == NATIVE ? address(this).balance : IERC20(_token).balanceOf(address(this));

        if (balanceInStrategy > balanceCapturedInPool) {
            uint256 excessFunds = balanceInStrategy - balanceCapturedInPool;
            uint256 bounty = (excessFunds * allo.getFeeSkirtingBountyPercentage()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            _transferAmount(_token, allo.getTreasury(), excessFunds);
            _transferAmount(_token, msg.sender, bounty);
            emit Skim(msg.sender, _token, excessFunds, bounty);
        }
    }

    function registerRecipient(bytes memory _data, address _sender)
        external
        payable
        onlyAllo
        onlyInitialized
        returns (address)
    {
        return _registerRecipient(_data, _sender);
    }

    function allocate(bytes memory _data, address _sender) external payable onlyAllo onlyInitialized {
        return _allocate(_data, _sender);
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        onlyAllo
        onlyInitialized
    {
        return _distribute(_recipientIds, _data, _sender);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    // set the pool to active or inactive
    function _setPoolActive(bool _active) internal {
        poolActive = _active;
        emit PoolActive(_active);
    }

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function _registerRecipient(bytes memory _data, address _sender) internal virtual returns (address);

    // only called via allo.sol by users to allocate to a recipient
    // this will update some data in this contract to store votes, etc.
    function _allocate(bytes memory _data, address _sender) internal virtual;

    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual;
}
