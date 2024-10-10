// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "strategies/BaseStrategy.sol";

contract MockBaseStrategy is BaseStrategy {
    uint256 internal surpressStateMutabilityWarning;

    constructor(address _allo, string memory _strategyName) BaseStrategy(_allo, _strategyName) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);
        _data;
        emit Initialized(_poolId, _data);
    }

    // this is called via allo.sol to register recipients
    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {
        surpressStateMutabilityWarning++;
        _data;
        _sender;
        return _recipients;
    }

    // only called via allo.sol by users to allocate to a recipient
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        surpressStateMutabilityWarning++;
        _recipients;
        _amounts;
        _data;
        _sender;
    }

    // this will distribute tokens to recipients
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {
        surpressStateMutabilityWarning++;
        _recipientIds;
        _data;
        _sender;
    }
}
