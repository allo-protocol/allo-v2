// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {AllocationExtension} from "strategies/extensions/allocate/AllocationExtension.sol";
// Internal Libraries
import {QFHelper} from "strategies/libraries/QFHelper.sol";
import {Native} from "contracts/core/libraries/Native.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Donation Voting Strategy with qudratic funding tracked on-chain
/// @notice Strategy that allows allocations in a specified token to accepted recipient. Payouts are calculated from
/// allocations based on the quadratic funding formula.
contract DonationVotingOnchain is BaseStrategy, RecipientsExtension, AllocationExtension, Native {
    using QFHelper for QFHelper.State;
    using Transfer for address;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when there is nothing to distribute for the given recipient.
    error NOTHING_TO_DISTRIBUTE(address recipientId);

    /// @notice Thrown when the timestamps being set or updated don't meet the contracts requirements.
    error INVALID_TIMESTAMPS();

    /// @notice Thrown when the allocation token is not allowed.
    error TOKEN_NOT_ALLOWED();

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Cooldown time from allocationEndTime after which the pool manager is allowed to withdraw tokens.
    uint64 public withdrawalCooldown;
    /// @notice amount to be distributed. It is set during the first distribute() call and stays fixed.
    uint256 public totalPayoutAmount;

    /// @notice recipientId -> amount
    mapping(address => uint256) public amountAllocated;

    /// @notice
    QFHelper.State public QFState;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Onchain strategy
    /// @param _allo The 'Allo' contract
    constructor(address _allo) RecipientsExtension(_allo, false) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (
    ///        RecipientInitializeData _recipientExtensionInitializeData,
    ///        uint64 _allocationStartTime,
    ///        uint64 _allocationEndTime,
    ///        uint64 _withdrawalCooldown,
    ///        address _allocationToken,
    ///        bool _isUsingAllocationMetadata
    ///    )
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (
            RecipientInitializeData memory _recipientExtensionInitializeData,
            uint64 _allocationStartTime,
            uint64 _allocationEndTime,
            uint64 _withdrawalCooldown,
            address _allocationToken,
            bool _isUsingAllocationMetadata
        ) = abi.decode(_data, (RecipientInitializeData, uint64, uint64, uint64, address, bool));

        withdrawalCooldown = _withdrawalCooldown;

        __BaseStrategy_init(_poolId);
        __RecipientsExtension_init(_recipientExtensionInitializeData);
        address[] memory _allowedTokens = new address[](1);
        _allowedTokens[0] = _allocationToken;
        __AllocationExtension_init(_allowedTokens, _allocationStartTime, _allocationEndTime, _isUsingAllocationMetadata);

        emit Initialized(_poolId, _data);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice This will allocate to recipients.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data containing the allocationToken and permit data for the sum of '_amounts' if needed (ignored if empty)
    /// @param _sender The address of the sender
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveAllocation
    {
        (address allocationToken, bytes memory permitData) = abi.decode(_data, (address, bytes));
        if (!_isAllowedToken(allocationToken)) revert TOKEN_NOT_ALLOWED();

        uint256 totalAmount;
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (!_isAcceptedRecipient(_recipients[i])) revert RECIPIENT_NOT_ACCEPTED();

            // Update the total payout amount for the claim and the total claimable amount
            amountAllocated[_recipients[i]] += _amounts[i];
            totalAmount += _amounts[i];

            emit Allocated(_recipients[i], _sender, _amounts[i], abi.encode(allocationToken));
        }

        if (allocationToken == NATIVE) {
            if (msg.value != totalAmount) revert ETH_MISMATCH();
        } else {
            allocationToken.usePermit(_sender, address(this), totalAmount, permitData);
            allocationToken.transferAmountFrom(_sender, address(this), totalAmount);
        }

        QFState.fund(_recipients, _amounts);
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data containing the allocation token
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        if (totalPayoutAmount == 0) totalPayoutAmount = poolAmount;

        (address allocationToken) = abi.decode(_data, (address));
        if (!_isAllowedToken(allocationToken)) revert TOKEN_NOT_ALLOWED();

        for (uint256 i; i < _recipientIds.length; i++) {
            address recipientId = _recipientIds[i];
            address recipientAddress = _recipients[recipientId].recipientAddress;

            if (amountAllocated[recipientId] == 0) revert NOTHING_TO_DISTRIBUTE(recipientId);

            // Transfer allocation
            uint256 allocationAmount = amountAllocated[recipientId];
            amountAllocated[recipientId] = 0;
            allocationToken.transferAmount(recipientAddress, allocationAmount);

            emit Distributed(recipientId, abi.encode(recipientAddress, allocationToken, allocationAmount, _sender));

            // Transfer matching amount
            uint256 matchingAmount = QFState.calculateMatching(totalPayoutAmount, recipientId);
            poolAmount -= matchingAmount;
            IAllo.Pool memory pool = allo.getPool(poolId);
            pool.token.transferAmount(recipientAddress, matchingAmount);

            emit Distributed(recipientId, abi.encode(recipientAddress, pool.token, matchingAmount, _sender));
        }
    }

    /// @notice Hook called before withdrawing tokens from the pool.
    function _beforeWithdraw(address, uint256, address) internal virtual override {
        if (block.timestamp <= allocationEndTime + withdrawalCooldown) revert INVALID();
    }

    /// @notice Hook called before increasing the pool amount.
    function _beforeIncreasePoolAmount(uint256) internal virtual override {
        if (block.timestamp > allocationEndTime) revert POOL_INACTIVE();
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return If the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool) {
        return _getRecipientStatus(_recipientId) == Status.Accepted;
    }

    function _isValidAllocator(address) internal view override returns (bool) {
        return true;
    }
}
