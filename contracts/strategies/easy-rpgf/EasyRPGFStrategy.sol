// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IAllo} from "../../core/interfaces/IAllo.sol";

contract EasyRPGFStrategy is BaseStrategy {
    error INPUT_LENGTH_MISMATCH();
    error NOOP();

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        emit Initialized(_poolId, _data);
    }

    /// @notice Withdraw pool funds
    /// @param _token Token address
    /// @param _recipient Address to send the funds to
    function withdraw(address _token, address _recipient) external onlyPoolManager(msg.sender) {
        uint256 _poolAmount = poolAmount;
        poolAmount = 0;
        _transferAmount(_token, _recipient, _poolAmount);
    }

    /// @notice Distribute pool funds
    /// @param _recipientIds Array of addresses to send the funds to
    /// @param _recipientAmounts Array of amounts that maps to _recipientIds array
    function _distribute(address[] memory _recipientIds, bytes memory _recipientAmounts, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        // Decode amounts from memory param
        uint256[] memory amounts = abi.decode(_recipientAmounts, (uint256[]));

        uint256 payoutLength = _recipientIds.length;

        // Assert at least one recipient
        if (payoutLength == 0) {
            revert INPUT_LENGTH_MISMATCH();
        }
        // Assert recipient and amounts length are equal
        if (payoutLength != amounts.length) {
            revert INPUT_LENGTH_MISMATCH();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        for (uint256 i; i < payoutLength;) {
            uint256 amount = amounts[i];
            address recipientAddress = _recipientIds[i];

            poolAmount -= amount;
            _transferAmount(pool.token, recipientAddress, amount);
            emit Distributed(recipientAddress, recipientAddress, amount, _sender);
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}

    // Not used in this Strategy
    function _allocate(bytes memory, address) internal virtual override {
        revert NOOP();
    }

    function _getRecipientStatus(address) internal view virtual override returns (Status) {
        revert NOOP();
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
