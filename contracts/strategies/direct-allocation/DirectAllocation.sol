// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";

contract DirectAllocationStrategy is BaseStrategy {
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        emit Initialized(_poolId, _data);
    }

    /// @notice Withdraw funds
    /// @param _token Token address
    /// @param _recipient Address to send the funds to
    function withdraw(address _token, address _recipient) external onlyPoolManager(msg.sender) {
        uint256 amount = _getBalance(_token, address(this));
        _transferAmount(_token, _recipient, amount);
    }

    /// Allocate funds to a recipient
    /// @param _data The data to allocate
    /// @param _sender The sender
    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));
        _transferAmountFrom(token, TransferData({from: _sender, to: recipientId, amount: amount}));
        emit Allocated(recipientId, amount, token, _sender);
    }

    receive() external payable {
        revert NOT_IMPLEMENTED();
    }

    // Not implemented

    function _distribute(address[] memory, bytes memory, address) internal virtual override {
        revert NOT_IMPLEMENTED();
    }

    function _getRecipientStatus(address) internal view virtual override returns (Status) {
        revert NOT_IMPLEMENTED();
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {}

    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {}

    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        virtual
        override
        returns (PayoutSummary memory)
    {}
}
