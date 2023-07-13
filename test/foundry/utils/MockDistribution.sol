// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/strategies/BaseStrategy.sol";

contract MockDistribution is BaseStrategy {
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, address _token, bytes memory _data)
        external
    {
        __BaseDistributionStrategy_init("MockDistribution", _allo, _identityId, _poolId, _token, _data);
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {}
}
