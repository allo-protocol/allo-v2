// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../core/Allo.sol";
import "../interfaces/IStrategy.sol";

abstract contract BaseStrategy is IStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error BaseStrategy_UNAUTHORIZED();
    error BaseStrategy_STRATEGY_ALREADY_INITIALIZED();
    error BaseStrategy_INVALID_ADDRESS();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    bytes32 internal STRATEGY_IDENTIFIER;

    bytes32 internal identityId;
    Allo internal allo;

    uint256 internal poolId;
    bool public initialized;

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the Allo contract
    modifier onlyAllo() {
        if (msg.sender != address(allo) && address(allo) != address(0)) {
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
    /// @param _allo Address of the Allo contract
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called internally by the strategy
    function __BaseStrategy_init(
        string memory _strategyIdentifier,
        address _allo,
        bytes32 _identityId,
        uint256 _poolId,
        bytes memory _data
    ) internal {
        if (initialized) {
            revert BaseStrategy_STRATEGY_ALREADY_INITIALIZED();
        }

        if (_allo == address(0)) {
            revert BaseStrategy_INVALID_ADDRESS();
        }

        initialized = true;

        _setStrategyIdentifier(_strategyIdentifier);

        allo = Allo(_allo);
        identityId = _identityId;
        poolId = _poolId;

        emit Initialized(_allo, _identityId, _poolId, _data);
    }

    /// @notice Get the identity id
    /// @return bytes32 The identity id
    function getIdentityId() external view returns (bytes32) {
        return identityId;
    }

    /// @notice Get the pool id
    /// @return uint256 The pool id
    function getPoolId() external view returns (uint256) {
        return poolId;
    }

    /// @notice Get the Allo address
    /// @return address The Allo address
    function getAllo() external view returns (address) {
        return address(allo);
    }

    /// @notice Returns the strategy identifier
    function getStrategyIdentifier() external view returns (bytes32) {
        return STRATEGY_IDENTIFIER;
    }

    /// @notice sets the strategy identifier
    /// @param _strategyIdentifier the strategy identifier
    function _setStrategyIdentifier(string memory _strategyIdentifier) internal {
        STRATEGY_IDENTIFIER = keccak256(abi.encode(_strategyIdentifier));
    }
}
