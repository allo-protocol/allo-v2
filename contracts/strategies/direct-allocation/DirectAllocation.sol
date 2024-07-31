// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";

contract DirectAllocationStrategy is BaseStrategy {
    event DirectAllocated(
        bytes32 indexed profileId, address profileOwner, uint256 amount, address token, address sender
    );

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
        (address profileOwner, uint256 amount, address token, uint256 nonce) =
            abi.decode(_data, (address, uint256, address, uint256));
        bytes32 profileId = keccak256(abi.encodePacked(nonce, profileOwner));

        _transferAmountFrom(token, TransferData({from: _sender, to: profileOwner, amount: amount}));
        emit DirectAllocated(profileId, profileOwner, amount, token, _sender);
    }

    receive() external payable {
        revert NOT_IMPLEMENTED();
    }

    function _beforeIncreasePoolAmount(uint256) internal virtual override {
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
