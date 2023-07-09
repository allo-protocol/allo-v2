// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IDistributionStrategy.sol";

contract MockDistribution is IDistributionStrategy {
    bytes32 public identityId;
    address public allo;
    uint256 public poolId;
    bool public initialized;

    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, address _token, bytes memory _data)
        external
    {
        if (initialized) {
            revert();
        }
        initialized = true;
        // surpress compiler warnings:
        _allo;
        _identityId;
        _poolId;
        _token;
        _data;
    }

    function distribute(uint256[] memory _recipientIds, bytes memory _data, address _sender) external {}

    function poolFunded(uint256 _amount) external {}
}
