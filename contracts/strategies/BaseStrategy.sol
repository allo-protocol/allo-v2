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
    /// =========== Modifier ===============
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
        bytes memory _recipientEligibilityData,
        bytes memory _voterEligibilityData,
        bytes memory _votingData,
        bytes memory _allocationData,
        bytes memory _distributionData
    ) external {
        require(msg.sender == address(allo), "only allo");

        // note: is it the case that identity id will never be 0? any reason it'd be better to use pool?
        require(_identityId != bytes32(0), "invalid identity id");
        require(identityId == bytes32(0), "already initialized");

        identityId = _identityId;
        poolId = _poolId;

        initializeRecipientEligibilityModule(_recipientEligibilityData);
        initializeVoterEligibilityModule(_voterEligibilityData);
        initializeVotingModule(_votingData);
        initializeAllocationModule(_allocationData);
        initializeDistributionModule(_distributionData);
    }
}
