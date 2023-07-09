// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../NoApplication.sol";
import {Allo} from "../../../../core/Allo.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract TokenBalanceNoApplication is NoApplication {
    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    uint256 public balanceThreshold;
    address public token;

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _allo Address of the Allo contract
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    // NOTE: this seems to be overriding a override...
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data)
        public
        virtual
        override
        onlyAllo
    {
        super.initialize(_allo, _identityId, _poolId, _data);
        if (initialized) {
            revert STRATEGY_ALREADY_INITIALIZED();
        }

        initialized = true;

        allo = Allo(_allo);
        identityId = _identityId;
        poolId = _poolId;

        // decode data
        (uint256 _balanceThreshold, address _token) = abi.decode(_data, (uint256, address));
        balanceThreshold = _balanceThreshold;
        token = _token;

        emit Initialized(_allo, _identityId, _poolId, _data);
    }

    /// @notice Checks if the sender is eligible for allocation
    function _isEligibleForAllocation(address _sender) internal view override returns (bool) {
        if (token == address(0)) {
            return address(_sender).balance >= balanceThreshold;
        }

        return IERC20(token).balanceOf(_sender) >= balanceThreshold;
    }
}
