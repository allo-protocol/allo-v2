// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Internal Imports
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
// Internal Libraries
import {Native} from "contracts/core/libraries/Native.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

/// @title DirectAllocationStrategy
/// @dev The strategy only implements the allocate logic
/// @notice A strategy that directly allocates funds to a recipient
contract DirectAllocationStrategy is BaseStrategy, Native, Errors {
    using Transfer for address;

    /// ===============================
    /// ============ Events ===========
    /// ===============================

    /// @notice Emitted when direct allocating to a recipient
    /// @param recipient The recipient
    /// @param amount The amount allocated
    /// @param token The token allocated
    /// @param sender The sender
    event DirectAllocated(address indexed recipient, uint256 amount, address token, address sender);

    /// ===============================
    /// ========= Constructor =========
    /// ===============================

    constructor(address _allo) BaseStrategy(_allo, "DirectAllocation") {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data to initialize the strategy
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        emit Initialized(_poolId, _data);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Allocate funds to a recipient
    /// @param _recipients The recipients
    /// @param _amounts The amounts to allocate
    /// @param _data The data to decode
    /// @param _sender The sender
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual
        override
    {
        /// Decode the data (data: tokens)
        address[] memory _tokens = abi.decode(_data, (address[]));

        uint256 _recipientsLength = _recipients.length;
        /// Check if inputs match the decoded data
        if (_recipientsLength != _amounts.length || _recipientsLength != _tokens.length) {
            revert ARRAY_MISMATCH();
        }

        uint256 _totalNativeAmount;
        for (uint256 i; i < _recipientsLength; ++i) {
            /// Direct allocate the funds
            if (_tokens[i] == NATIVE) _totalNativeAmount += _amounts[i];
            _tokens[i].transferAmountFrom(_sender, _recipients[i], _amounts[i]);

            emit DirectAllocated(_recipients[i], _amounts[i], _tokens[i], _sender);
        }

        if (msg.value < _totalNativeAmount) revert ETH_MISMATCH();
    }

    /// @inheritdoc BaseStrategy
    function _distribute(address[] memory, bytes memory, address) internal virtual override {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseStrategy
    function _register(address[] memory, bytes memory, address) internal virtual override returns (address[] memory) {
        revert NOT_IMPLEMENTED();
    }

    /// @notice Fallback function to receive ether
    /// @dev This function is not implemented, should not receive ether
    receive() external payable virtual override {
        revert NOT_IMPLEMENTED();
    }
}
