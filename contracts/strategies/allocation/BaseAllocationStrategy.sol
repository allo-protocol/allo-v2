// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../BaseStrategy.sol";
import "../../interfaces/IAllocationStrategy.sol";

abstract contract BaseAllocationStrategy is BaseStrategy, IAllocationStrategy {
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
        __BaseStrategy_init(_allo, _identityId, _poolId, _data);
    }
}
