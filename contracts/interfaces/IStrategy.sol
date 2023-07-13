// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IStrategy {
    /**
     * STORAGE (with public getters)
     *     bool initialized;
     *     bytes32 identityId;
     *     uint256 poolId;
     *     address allo;
     */

    struct PayoutSummary {
        address payoutAddress;
        uint256 percentage;
        uint256 amount;
    }

    /// @notice Get the strategy identifier
    /// @return bytes32 The strategy identifier
    function getStrategyIdentifier() external view returns (bytes32);

    /// @notice Get the identity id
    /// @return bytes32 The identity id
    function getIdentityId() external view returns (bytes32);

    /// @notice Get the Allo address
    /// @return uint256 The Allo address
    function getAllo() external view returns (address);

    /// @notice Get the pool id
    /// @return uint256 The pool id
    function getPoolId() external view returns (uint256);
}
