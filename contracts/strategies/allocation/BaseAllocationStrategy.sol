// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../interfaces/IAllocationStrategy.sol";
import "../../core/Allo.sol";

abstract contract BaseAllocationStrategy is IAllocationStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error UNAUTHORIZED();
    error STRATEGY_ALREADY_INITIALIZED();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);

    // Note: this is mapped to the Allo global status's in the mapping below.
    /// @notice Enum for the local status of the recipent
    enum Status {
        PENDING,
        ACCEPTED,
        REJECTED,
        REAPPLIED
    }

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    bytes32 public identityId;
    Allo public allo;

    uint256 public poolId;
    bool public initialized;

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the Allo contract
    modifier onlyAllo() {
        if (msg.sender != address(allo) || address(allo) == address(0)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the caller is a pool manager
    modifier onlyPoolManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert UNAUTHORIZED();
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
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data)
        public
        virtual
        override
        onlyAllo
    {
        if (initialized) {
            revert STRATEGY_ALREADY_INITIALIZED();
        }

        initialized = true;

        allo = Allo(_allo);
        identityId = _identityId;
        poolId = _poolId;

        emit Initialized(_allo, _identityId, _poolId, _data);
    }
}
