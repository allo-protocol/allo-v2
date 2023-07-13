// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Allo} from "../core/Allo.sol";
import {IStrategy} from "./IStrategy.sol";

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

    Allo public immutable allo;

    uint256 public poolId;
    bytes32 public ownerIdentityId;

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
    function initialize(
        bytes32 _identityId,
        uint256 _poolId,
        bytes memory _data
    ) external virtual onlyAllo {
        require(_identityId != bytes32(0), "invalid identity id");
        require(identityId == bytes32(0), "already initialized");

        identityId = _identityId;
        poolId = _poolId;
    }

    function skim(address _token) external {
        Allo.Pool memory pool = allo.pools(poolId);
        uint fundedBalance;
        if (pool.token == _token) {
            fundedBalance = pool.fundedBalance;
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > fundedBalance) {
            uint excessFunds = balance - fundedBalance;
            uint bounty = (excessFunds * allo.feeSkirtingBounty()) / allo.FEE_DENOMINATOR();
            excessFunds -= bounty;
            IERC20(_token).transfer(treasury, excessFunds);
            IERC20(_token).transfer(msg.sender, bounty);
        }
    }
}
