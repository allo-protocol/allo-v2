// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import "../core/interfaces/IStrategy.sol";

// Libraries
import {Transfer} from "../core/libraries/Transfer.sol";

/// @title BaseStrategy Contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice This contract is the base contract for all strategies
/// @dev This contract is implemented by all strategies.
abstract contract BaseStrategy is IStrategy, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    IAllo internal immutable allo;
    bytes32 internal immutable strategyId;
    bool internal poolActive;
    uint256 internal poolId;
    uint256 internal poolAmount;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor to set the Allo contract and "strategyId'.
    /// @param _allo Address of the Allo contract.
    /// @param _name Name of the strategy
    constructor(address _allo, string memory _name) {
        allo = IAllo(_allo);
        strategyId = keccak256(abi.encode(_name));
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    modifier onlyAllo() {
        if (msg.sender != address(allo)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    modifier onlyPoolManager(address _sender) {
        if (!allo.isPoolManager(poolId, _sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the pool is active.
    /// @dev Reverts if the pool is not active.
    modifier onlyActivePool() {
        if (!poolActive) {
            revert BaseStrategy_POOL_INACTIVE();
        }
        _;
    }

    /// @notice Modifier to check if the pool is inactive.
    /// @dev Reverts if the pool is active.
    modifier onlyInactivePool() {
        if (poolActive) {
            revert BaseStrategy_POOL_ACTIVE();
        }
        _;
    }

    /// @notice Modifier to check if the pool is initialized.
    /// @dev Reverts if the pool is not initialized.
    modifier onlyInitialized() {
        if (poolId == 0) {
            revert BaseStrategy_NOT_INITIALIZED();
        }
        _;
    }

    /// ================================
    /// =========== Views ==============
    /// ================================

    /// @notice Getter for the 'Allo' contract.
    /// @return The Allo contract
    function getAllo() external view override returns (IAllo) {
        return allo;
    }

    /// @notice Getter for the 'poolId'.
    /// @return The ID of the pool
    function getPoolId() external view override returns (uint256) {
        return poolId;
    }

    /// @notice Getter for the 'strategyId'.
    /// @return The ID of the strategy
    function getStrategyId() external view override returns (bytes32) {
        return strategyId;
    }

    /// @notice Getter for the 'poolAmount'.
    /// @return The balance of the pool
    function getPoolAmount() external view virtual override returns (uint256) {
        return poolAmount;
    }

    /// @notice Getter for whether or not the pool is active.
    /// @return 'true' if the pool is active, otherwise 'false'
    function isPoolActive() external view override returns (bool) {
        return _isPoolActive();
    }

    /// @notice Getter for the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function getRecipientStatus(address _recipientId) external view virtual returns (RecipientStatus) {
        return _getRecipientStatus(_recipientId);
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the 'Basetrategy'.
    /// @dev Will revert if the poolId is invalid or already initialized
    /// @param _poolId ID of the pool
    function __BaseStrategy_init(uint256 _poolId) internal virtual onlyAllo {
        if (poolId != 0) {
            revert BaseStrategy_ALREADY_INITIALIZED();
        }
        if (_poolId == 0) {
            revert BaseStrategy_INVALID();
        }
        poolId = _poolId;
    }

    /// @notice Increases the pool amount.
    /// @dev Increases the 'poolAmount' by '_amount'. Only 'Allo' contract can call this.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external override onlyAllo {
        _beforeIncreasePoolAmount(_amount);
        poolAmount += _amount;
        _afterIncreasePoolAmount(_amount);
    }

    /// @notice Registers a recipient.
    /// @dev Registers a recipient and returns the ID of the recipient. The encoded '_data' will be determined by the
    ///      strategy implementation. Only 'Allo' contract can call this when it is initialized.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The recipientId
    function registerRecipient(bytes memory _data, address _sender)
        external
        payable
        onlyAllo
        onlyInitialized
        returns (address)
    {
        _beforeRegisterRecipient(_data, _sender);
        address recipientId = _registerRecipient(_data, _sender);
        _afterRegisterRecipient(_data, _sender);

        return recipientId;
    }

    /// @notice Allocates to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(bytes memory _data, address _sender) external payable onlyAllo onlyInitialized {
        _beforeAllocate(_data, _sender);
        _allocate(_data, _sender);
        _afterAllocate(_data, _sender);
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        onlyAllo
        onlyInitialized
    {
        _beforeDistribute(_recipientIds, _data, _sender);
        _distribute(_recipientIds, _data, _sender);
        _afterDistribute(_recipientIds, _data, _sender);
    }

    /// @notice Gets the payout summary for recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to get the payout summary for the recipients
    /// @return The payout summary for the recipients
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        virtual
        override
        returns (PayoutSummary[] memory)
    {
        uint256 length = _recipientIds.length;
        if (length != _data.length) {
            revert BaseStrategy_ARRAY_MISMATCH();
        }
        PayoutSummary[] memory payouts = new PayoutSummary[](length);
        for (uint256 i = 0; i < length;) {
            payouts[i] = _getPayout(_recipientIds[i], _data[i]);
            unchecked {
                i++;
            }
        }
        return payouts;
    }

    /// @notice Checks if the '_allocator' is a valid allocator.
    /// @dev How the allocator is determined is up to the strategy implementation.
    /// @param _allocator The address to check if it is a valid allocator for the strategy.
    /// @return 'true' if the address is a valid allocator, 'false' otherwise
    function isValidAllocator(address _allocator) external view virtual override returns (bool) {
        return _isValidAllocator(_allocator);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Set the pool to active or inactive status.
    /// @dev This will emit a 'PoolActive()' event. Used by the strategy implementation.
    /// @param _active The status to set, 'true' means active, 'false' means inactive
    function _setPoolActive(bool _active) internal {
        poolActive = _active;
        emit PoolActive(_active);
    }

    /// @notice Checks if the pool is active.
    /// @dev Used by the strategy implementation.
    /// @return 'true' if the pool is active, otherwise 'false'
    function _isPoolActive() internal view virtual returns (bool) {
        return poolActive;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view virtual returns (bool);

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to Accepted, or to Pending and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then Accept for instance.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender) internal virtual returns (address);

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(bytes memory _data, address _sender) internal virtual;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual;

    /// @notice This will get the payout summary for a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientId The ID of the recipient
    /// @param _data The data to use to get the payout summary for the recipient
    /// @return The payout summary for the recipient
    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        virtual
        returns (PayoutSummary memory);

    /// @notice This will get the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual returns (RecipientStatus);

    /// ===================================
    /// ============== Hooks ==============
    /// ===================================

    /// @notice Hook called before increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called after increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _afterIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called before registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _beforeRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _afterRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _beforeAllocate(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _afterAllocate(bytes memory _data, address _sender) internal virtual {}

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
}
