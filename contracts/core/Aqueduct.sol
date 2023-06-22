// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract Aqueduct {
    constructor() {}

    /**
        STORAGE (with public getters)
        address owner; // & all ownership transfer logic
        address allo;
    */

    // can receive ETH
    receive() external payable {
        // NOTE: receive ETH
    }

    /// @notice 
    function createPool(
        address _identity,
        address _allocationStrategy,
        address _distributionStrategy,
        bytes memory _metadata
    ) external payable returns (uint256) {
        // NOTE: create pool
    }
}
