// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../BaseStrategy.sol";
import "../../interfaces/IDistributionStrategy.sol";
import "../../interfaces/IAllocationStrategy.sol";

abstract contract BaseDistributionStrategy is BaseStrategy, IDistributionStrategy {
    /// ======================
    /// ======= Events =======
    /// ======================
    event TokenSet(address _token);
    event PoolFundingIncreased(uint256 amount);

    /// ==========================
    /// === Storage Variables ====
    /// ==========================
    uint256 public amount;
    address public token;

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _strategyIdentifier The identifier of the strategy
    /// @param _allo Address of the Allo contract
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    function __BaseDistributionStrategy_init(
        string memory _strategyIdentifier,
        address _allo,
        bytes32 _identityId,
        uint256 _poolId,
        address _token,
        bytes memory _data
    ) internal onlyAllo {
        __BaseStrategy_init(_strategyIdentifier, _allo, _identityId, _poolId, _data);
        token = _token;
        emit TokenSet(_token);
    }

    /// @notice invoked via allo.fundPool to update pool's amount
    /// @param _amount amount by which pool is increased
    function poolFunded(uint256 _amount) public virtual onlyAllo {
        amount += _amount;
        emit PoolFundingIncreased(amount);
    }
}
