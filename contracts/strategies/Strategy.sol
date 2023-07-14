// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../core/Allo.sol";
import "./IStrategy.sol";

abstract contract Strategy is IStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error Strategy_UNAUTHORIZED();
    error Strategy_ALREADY_INITIALIZED();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 ownerIdentityId, uint256 poolId, bytes data);

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    bytes32 internal immutable STRATEGY_IDENTIFIER;
    bytes32 internal ownerIdentityId;
    Allo internal immutable allo;
    uint256 internal poolId;
    bool public initialized;

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the Allo contract
    modifier onlyAllo() {
        if (msg.sender != address(allo) && address(allo) != address(0)) {
            revert Strategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the caller is a pool manager
    modifier onlyPoolManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert Strategy_UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _ownerIdentityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called internally by the strategy
    function initialize(bytes32 _ownerIdentityId, uint256 _poolId, bytes memory _data) external virtual onlyAllo {
        if (initialized) {
            revert Strategy_ALREADY_INITIALIZED();
        }

        initialized = true;

        ownerIdentityId = _ownerIdentityId;
        poolId = _poolId;

        emit Initialized(_allo, _ownerIdentityId, _poolId, _data);
    }

    /// @notice Can be called when contract balance is greater than the amount captured in Allo.pool
    /// the remaining balance will be split between the treasury and the msg.sender
    /// @param _token Address of the token
    function skim(address _token) external override {
        (,, address token, uint256 amount,,,) = allo.pools(poolId);

        uint256 balanceCapturedInPool = (token == _token) ? amount : 0;
        uint256 balanceInStrategy =
            _token == address(0) ? address(this).balance : IERC20(_token).balanceOf(address(this));

        if (balanceInContract > balanceCapturedInPool) {
            uint256 excessFunds = balanceInStrategy - balanceCapturedInPool;
            uint256 bounty = (excessFunds * allo.feeSkirtingBounty()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            IERC20(_token).transfer(allo.treasury(), excessFunds);
            IERC20(_token).transfer(msg.sender, bounty);
        }
    }

    /// @notice Get the identity id
    /// @return bytes32 The identity id
    function getOwnerIdentityId() external view returns (bytes32) {
        return ownerIdentityId;
    }

    /// @notice Get the pool id
    /// @return uint256 The pool id
    function getPoolId() external view returns (uint256) {
        return poolId;
    }

    /// @return address The Allo address
    function getAllo() external view returns (address) {
        return address(allo);
    }

    /// @notice Returns the strategy identifier
    function getStrategyIdentifier() external view returns (bytes32) {
        return STRATEGY_IDENTIFIER;
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice sets the strategy identifier
    /// @param _strategyIdentifier the strategy identifier
    function _setStrategyIdentifier(string memory _strategyIdentifier) internal {
        STRATEGY_IDENTIFIER = keccak256(abi.encode(_strategyIdentifier));
    }
}
