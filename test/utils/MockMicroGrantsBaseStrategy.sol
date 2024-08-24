// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {MicroGrantsBaseStrategy} from "../../contracts/strategies/_poc/micro-grants/MicroGrantsBaseStrategy.sol";

contract MockMicroGrantsBaseStrategy is MicroGrantsBaseStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The 'Allo' contract
    constructor(address _allo, string memory _name) MicroGrantsBaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams) = abi.decode(_data, (InitializeParams));
        __MicroGrants_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    function _isValidAllocator(address) internal pure override returns (bool) {
        return true;
    }
}
