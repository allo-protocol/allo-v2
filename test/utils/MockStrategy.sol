// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../../contracts/strategies/BaseStrategy.sol";

contract MockStrategy is BaseStrategy {
    uint256 internal surpressStateMutabilityWarning;

    constructor(address _allo) BaseStrategy(_allo, "MockStrategy") {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);
        _data;
        emit Initialized(_poolId, _data);
    }

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address) {
        surpressStateMutabilityWarning++;
        _data;
        return _sender;
    }

    // only called via allo.sol by users to allocate to a recipient
    // this will update some data in this contract to store votes, etc.
    function _allocate(bytes memory _data, address _sender) internal override {
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

    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        surpressStateMutabilityWarning;
        return _recipientId == address(0) ? Status.Rejected : Status.Accepted;
    }

    /// @return Input the values you would send to distribute(), get the amounts each recipient in the array would receive
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        override
        returns (PayoutSummary[] memory)
    {
        surpressStateMutabilityWarning;

        PayoutSummary[] memory payouts = new PayoutSummary[](_recipientIds.length);

        for (uint256 i; i < _recipientIds.length; i++) {
            payouts[i] = abi.decode(_data[i], (PayoutSummary));
        }

        return payouts;
    }

    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        override
        returns (PayoutSummary memory)
    {
        surpressStateMutabilityWarning;
        _data;
        return PayoutSummary(_recipientId, 0);
    }

    // simply returns whether a allocator is valid or not, will usually be true for all
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        surpressStateMutabilityWarning;
        return _allocator == address(0) ? false : true;
    }

    function setPoolActive(bool _active) external {
        _setPoolActive(_active);
    }
}
