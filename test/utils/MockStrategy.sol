// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "contracts/strategies/CoreBaseStrategy.sol";

contract MockStrategy is CoreBaseStrategy {
    uint256 internal surpressStateMutabilityWarning;

    constructor(address _allo) CoreBaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);
        _data;
        emit Initialized(_poolId, _data);
    }

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {
        surpressStateMutabilityWarning++;
        _data;
        return _recipients;
    }

    // only called via allo.sol by users to allocate to a recipient
    // this will update some data in this contract to store votes, etc.
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        surpressStateMutabilityWarning++;
        _data;
        _sender;
    }

    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {
        surpressStateMutabilityWarning++;
        _recipientIds;
        _data;
        _sender;
    }
}
