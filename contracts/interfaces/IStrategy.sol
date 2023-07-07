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

    // initialize the strategy with the poolId and allo address
    // set initialized to true and ensure it can't be called again
    // check if identityId passed, is same as the identityId set during deployment
    // if identityId is not set during deployment, then set it (for clones)
    function initialize(bytes32 _identityId, uint256 _poolId, address _allo, bytes memory _data) external;

    // call to allo() to get identity for pool, then to registry() to get metadata
    function getOwnerIdentity() external view returns (string memory);
}
