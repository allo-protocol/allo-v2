// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";

contract YeeterStrategy is BaseStrategy {
    error INPUT_LENGTH_MISMATCH();
    error NOOP();

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        emit Initialized(_poolId, _data);
    }

    /// @notice Withdraw funds stuck on contract
    /// @param _token Token address
    /// @param _recipient Address to send the funds to
    /// @param _amount Amount to withdraw
    function withdraw(address _token, address _recipient, uint256 _amount) external onlyPoolManager(msg.sender) {
        _transferAmount(_token, _recipient, _amount);
    }

    receive() external payable {}

    /// @notice Allocate Yeeter funds to recipients
    /// @param _data Array of recipientAddress , Array of amounts and the token address to allocate the funds to
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyPoolManager(_sender) {
        // Decode the data
        (address[] memory _recipientIds, uint256[] memory _amounts, address _token) =
            abi.decode(_data, (address[], uint256[], address));

        uint256 payoutLength = _recipientIds.length;

        // Assert at least one recipient
        if (payoutLength == 0) {
            revert INPUT_LENGTH_MISMATCH();
        }

        // Assert recipient and amounts length are equal
        if (payoutLength != _amounts.length) {
            revert INPUT_LENGTH_MISMATCH();
        }

        for (uint256 i; i < payoutLength;) {
            uint256 _amount = _amounts[i];
            address _recipientId = _recipientIds[i];

            _transferAmount(_token, _recipientId, _amount);
            emit Allocated(_recipientId, _amount, _token, _sender);
            unchecked {
                ++i;
            }
        }
    }

    // Not used in this Strategy
    function _distribute(address[] memory, bytes memory, address) internal virtual override {
        revert NOOP();
    }

    function _getRecipientStatus(address) internal view virtual override returns (Status) {
        revert NOOP();
    }

    function _isValidAllocator(address) internal view virtual override returns (bool) {
        revert NOOP();
    }

    function _registerRecipient(bytes memory, address) internal virtual override returns (address) {
        revert NOOP();
    }

    function _getPayout(address, bytes memory) internal view virtual override returns (PayoutSummary memory) {
        revert NOOP();
    }
}
