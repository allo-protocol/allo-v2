// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IStrategy.sol";

interface IDistributionStrategy is IStrategy {
    // initialize the strategy with the poolId and allo address
    // set initialized to true and ensure it can't be called again
    // check if identityId passed, is same as the identityId set during deployment
    // if identityId is not set during deployment, then set it (for clones)
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, address _token, bytes memory _data)
        external;

    // distribution a payout based on the strategy's needs
    // this could include merkle proofs, etc or just nothing
    function distribute(uint256[] memory _recipentIds, bytes memory _data, address _sender) external;

    // invoked by Allo.fundPool
    function poolFunded(uint256 _amount) external;

    // many owners will probably want a way to update roots, pull out funds if not claimed, etc
    // but all of that will be in specific implementations, not requried interface
}
