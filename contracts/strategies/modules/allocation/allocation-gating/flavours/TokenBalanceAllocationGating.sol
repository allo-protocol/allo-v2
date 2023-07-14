// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../AllocationGating.sol";
import {Allo} from "../../../../core/Allo.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract TokenBalanceAllocationGating is AllocationGating {
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
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public override {
        __BaseAllocationStrategy_init("TokenBalanceAllocationGatingV1", _allo, _identityId, _poolId, _data);

        // decode data custom to this strategy
        (uint256 _balanceThreshold, address _token) = abi.decode(_data, (uint256, address));
        balanceThreshold = _balanceThreshold;
        token = _token;
    }

    /// @notice Checks if recipient owns token balance greater than threshold
    /// @param _recipient Address of the recipient
    function _isEligibleForAllocation(address _recipient) internal view override returns (bool) {
        if (token == address(0)) {
            return address(_recipient).balance >= balanceThreshold;
        }

        return IERC20(token).balanceOf(_recipient) >= balanceThreshold;
    }
}
