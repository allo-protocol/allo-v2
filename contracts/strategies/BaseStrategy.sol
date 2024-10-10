/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IBaseStrategy} from "strategies/IBaseStrategy.sol";
// Internal Libraries
import {Transfer} from "contracts/core/libraries/Transfer.sol";

/// @title BaseStrategy Contract
/// @notice This contract is the base contract for all strategies
/// @dev This contract is implemented by all strategies.
abstract contract BaseStrategy is IBaseStrategy {
    using Transfer for address;

    /// ==========================
    /// === Storage Variables ====
    /// ==========================
    /// @notice The Allo contract
    IAllo internal immutable _ALLO;
    /// @notice The id of the pool
    uint256 internal _poolId;
    /// @notice The balance of the pool
    uint256 internal _poolAmount;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor to set the Allo contract
    /// @param _allo Address of the Allo contract.
    constructor(address _allo) {
        _ALLO = IAllo(_allo);
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================
    /// @notice Modifier to check if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    modifier onlyAllo() {
        _checkOnlyAllo();
        _;
    }

    /// @notice Modifier to check if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    modifier onlyPoolManager(address _sender) {
        _checkOnlyPoolManager(_sender);
        _;
    }

    /// ================================
    /// =========== Views ==============
    /// ================================

    /// @notice Gets the allo contract
    /// @return _allo The 'Allo' contract
    function getAllo() external view override returns (IAllo) {
        return _ALLO;
    }

    /// @notice Getter for the '_poolId'.
    /// @return __poolId The ID of the pool
    function getPoolId() external view override returns (uint256) {
        return _poolId;
    }

    /// @notice Getter for the '_poolAmount'.
    /// @return __poolAmount The balance of the pool
    function getPoolAmount() external view virtual override returns (uint256) {
        return _poolAmount;
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the 'Basetrategy'.
    /// @dev Will revert if the _poolId is invalid or already initialized
    /// @param __poolId ID of the pool
    function __BaseStrategy_init(uint256 __poolId) internal virtual onlyAllo {
        // check if pool ID is not initialized already, if it is, revert
        if (_poolId != 0) revert BaseStrategy_AlreadyInitialized();

        // check if pool ID is valid and not zero (0), if it is, revert
        if (__poolId == 0) revert BaseStrategy_InvalidPoolId();
        _poolId = __poolId;
    }

    /// @notice Increases the pool amount.
    /// @dev Increases the '_poolAmount' by '_amount'. Only 'Allo' contract can call this.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external override onlyAllo {
        _beforeIncreasePoolAmount(_amount);
        _poolAmount += _amount;
        _afterIncreasePoolAmount(_amount);
    }

    /// @notice Withdraws tokens from the pool.
    /// @dev Withdraws '_amount' of '_token' to '_recipient'
    /// @param _token The address of the token
    /// @param _amount The amount to withdraw
    /// @param _recipient The address to withdraw to
    function withdraw(address _token, uint256 _amount, address _recipient)
        external
        override
        onlyPoolManager(msg.sender)
    {
        _beforeWithdraw(_token, _amount, _recipient);
        // If the token is the pool token, revert if the amount is greater than the pool amount
        if (_token == _ALLO.getPool(_poolId).token) {
            if (_token.getBalance(address(this)) - _amount < _poolAmount) {
                revert BaseStrategy_WithdrawMoreThanPoolAmount();
            }
        }
        _token.transferAmount(_recipient, _amount);
        _afterWithdraw(_token, _amount, _recipient);

        emit Withdrew(_token, _amount, _recipient);
    }

    /// @notice Registers recipients to the strtategy.
    /// @dev Registers multiple recipient and returns the IDs of the recipients. The encoded '_data' will be determined by the
    ///      strategy implementation. Only 'Allo' contract can call this when it is initialized.
    /// @param _recipients The addresses of the recipients to register
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return _recipientIds The recipientIds
    function register(address[] memory _recipients, bytes memory _data, address _sender)
        external
        payable
        onlyAllo
        returns (address[] memory _recipientIds)
    {
        _beforeRegisterRecipient(_recipients, _data, _sender);
        _recipientIds = _register(_recipients, _data, _sender);
        _afterRegisterRecipient(_recipients, _data, _sender);
    }

    /// @notice Allocates to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        external
        payable
        onlyAllo
    {
        _beforeAllocate(_recipients, _data, _sender);
        _allocate(_recipients, _amounts, _data, _sender);
        _afterAllocate(_recipients, _data, _sender);
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external onlyAllo {
        _beforeDistribute(_recipientIds, _data, _sender);
        _distribute(_recipientIds, _data, _sender);
        _afterDistribute(_recipientIds, _data, _sender);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    function _checkOnlyAllo() internal view virtual {
        if (msg.sender != address(_ALLO)) revert BaseStrategy_Unauthorized();
    }

    /// @notice Checks if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    function _checkOnlyPoolManager(address _sender) internal view virtual {
        if (!_ALLO.isPoolManager(_poolId, _sender)) revert BaseStrategy_Unauthorized();
    }

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to Accepted, or to Pending and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then Accept for instance.
    /// @param _recipients The addresses of the recipients to register
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return _recipientIds The ID of the recipient
    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        returns (address[] memory _recipientIds);

    /// @notice This will allocate to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual;

    /// ===================================
    /// ============== Hooks ==============
    /// ===================================

    /// @notice Hook called before increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called after increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _afterIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called before withdrawing tokens from the pool.
    /// @param _token The address of the token
    /// @param _amount The amount to withdraw
    /// @param _recipient The address to withdraw to
    function _beforeWithdraw(address _token, uint256 _amount, address _recipient) internal virtual {}

    /// @notice Hook called after withdrawing tokens from the pool.
    /// @param _token The address of the token
    /// @param _amount The amount to withdraw
    /// @param _recipient The address to withdraw to
    function _afterWithdraw(address _token, uint256 _amount, address _recipient) internal virtual {}

    /// @notice Hook called before registering a recipient.
    /// @param _recipients The addresses of the recipients to register
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _beforeRegisterRecipient(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
    {}

    /// @notice Hook called after registering a recipient.
    /// @param _recipients The addresses of the recipients to register
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _afterRegisterRecipient(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
    {}

    /// @notice Hook called before allocating to a recipient.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _beforeAllocate(address[] memory _recipients, bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after allocating to a recipient.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _afterAllocate(address[] memory _recipients, bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _beforeDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _afterDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}

    /// @notice Strategies should be able to receive native token
    /// @dev By default onlyAllo should be able to call this to fund the pool
    /// @dev In case of a strategy that needs to receive native token from other sources, this function should be overridden
    receive() external payable virtual onlyAllo {}
}
