// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {AllocationExtension} from "strategies/extensions/allocate/AllocationExtension.sol";
// Internal Libraries
import {Transfer} from "contracts/core/libraries/Transfer.sol";
import {Native} from "contracts/core/libraries/Native.sol";

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

/// @title Donation Voting Strategy with off-chain setup
/// @notice Strategy that allows allocations in multiple tokens to accepted recipient. The actual payouts are set
/// by the pool manager.
contract DonationVotingOffchain is BaseStrategy, RecipientsExtension, AllocationExtension, Native {
    using Transfer for address;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a recipient claims the tokens allocated to it
    /// @param recipientId Id of the recipient
    /// @param amount The amount of pool tokens claimed
    /// @param token The token address of the amount being claimed
    event Claimed(address indexed recipientId, uint256 amount, address token);

    /// @notice Emitted when the payout amount for a recipient is set
    /// @param recipientId Id of the recipient
    /// @param amount The amount of pool tokens set
    event PayoutSet(address indexed recipientId, uint256 amount);

    /// ================================
    /// ========== Errors ==============
    /// ================================

    /// @notice Thrown when there is nothing to distribute for the given recipient.
    /// @param recipientId The recipientId to which distribution was attempted.
    error DonationVotingOffchain_NothingToDistribute(address recipientId);

    /// @notice Thrown when a the payout for a recipient is attempted to be overwritten.
    /// @param recipientId The recipientId to which a repeated payout was attempted.
    error DonationVotingOffchain_PayoutAlreadySet(address recipientId);

    /// @notice Thrown when the total payout amount is greater than the pool amount.
    error DonationVotingOffchain_PayoutsExceedPoolAmount();

    /// @notice Thrown when the token used was not whitelisted.
    error DonationVotingOffchain_TokenNotAllowed();

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Payout summary struct to hold the payout data
    /// @param recipientAddress payout address of the recipient
    /// @param amount payout amount
    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// @notice Struct to hold details of the allocations to claim
    /// @param recipientId id of the recipient
    /// @param token token address
    struct Claim {
        address recipientId;
        address token;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice If true, allocations are directly sent to recipients. Otherwise, they they must be claimed later.
    bool public immutable DIRECT_TRANSFER;

    /// @notice Cooldown time from allocationEndTime after which the pool manager is allowed to withdraw tokens.
    uint64 public withdrawalCooldown;
    /// @notice amount to be distributed. `totalPayoutAmount` get reduced with each distribution.
    uint256 public totalPayoutAmount;

    /// @notice recipientId -> PayoutSummary
    mapping(address => PayoutSummary) public payoutSummaries;
    /// @notice recipientId -> token -> amount
    mapping(address => mapping(address => uint256)) public amountAllocated;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Offchain strategy
    /// @param _allo The 'Allo' contract
    /// @param _directTransfer false if allocations must be manually claimed, true if they are sent during allocation.
    constructor(address _allo, bool _directTransfer) RecipientsExtension(_allo, false) {
        DIRECT_TRANSFER = _directTransfer;
    }

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
    ///        address[] _allowedTokens,
    ///        bool _isUsingAllocationMetadata
    ///    )
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (
            RecipientInitializeData memory _recipientExtensionInitializeData,
            uint64 _allocationStartTime,
            uint64 _allocationEndTime,
            uint64 _withdrawalCooldown,
            address[] memory _allowedTokens,
            bool _isUsingAllocationMetadata
        ) = abi.decode(_data, (RecipientInitializeData, uint64, uint64, uint64, address[], bool));

        withdrawalCooldown = _withdrawalCooldown;

        __BaseStrategy_init(_poolId);
        __RecipientsExtension_init(_recipientExtensionInitializeData);
        __AllocationExtension_init(_allowedTokens, _allocationStartTime, _allocationEndTime, _isUsingAllocationMetadata);

        emit Initialized(_poolId, _data);
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Transfers the allocated tokens to recipients.
    /// @dev This function is ignored if DIRECT_TRANSFER is enabled, in which case allocated tokens are not stored
    /// in the contract for later claim but directly sent to recipients in `_allocate()`.
    /// @param _data The data to be decoded
    /// @custom:data (Claim[] _claims)
    function claimAllocation(bytes memory _data) external virtual onlyAfterAllocation {
        if (DIRECT_TRANSFER) revert NOT_IMPLEMENTED();

        (Claim[] memory _claims) = abi.decode(_data, (Claim[]));

        uint256 _claimsLength = _claims.length;
        for (uint256 i; i < _claimsLength; i++) {
            Claim memory _claim = _claims[i];
            uint256 _amount = amountAllocated[_claim.recipientId][_claim.token];
            address _recipientAddress = _recipients[_claim.recipientId].recipientAddress;

            amountAllocated[_claim.recipientId][_claim.token] = 0;

            _claim.token.transferAmount(_recipientAddress, _amount);

            emit Claimed(_claim.recipientId, _amount, _claim.token);
        }
    }

    /// @notice Sets the payout amounts to be distributed to.
    /// @param _data The data to be decoded
    /// @custom:data (address[] _recipientIds, uint256[] _amounts)
    function setPayout(bytes memory _data) external virtual onlyPoolManager(msg.sender) onlyAfterAllocation {
        (address[] memory _recipientIds, uint256[] memory _amounts) = abi.decode(_data, (address[], uint256[]));

        uint256 _totalAmount;
        for (uint256 i; i < _recipientIds.length; i++) {
            address _recipientId = _recipientIds[i];
            if (!_isAcceptedRecipient(_recipientId)) revert RecipientsExtension_RecipientNotAccepted();

            PayoutSummary storage payoutSummary = payoutSummaries[_recipientId];
            if (payoutSummary.amount != 0) revert DonationVotingOffchain_PayoutAlreadySet(_recipientId);

            uint256 _amount = _amounts[i];
            _totalAmount += _amount;

            payoutSummary.amount = _amount;
            payoutSummary.recipientAddress = _recipients[_recipientId].recipientAddress;

            emit PayoutSet(_recipientId, _amount);
        }

        totalPayoutAmount += _totalAmount;
        if (totalPayoutAmount > _poolAmount) revert DonationVotingOffchain_PayoutsExceedPoolAmount();
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice This will allocate to recipients.
    /// @dev The encoded '_data' is a tuple containing an array of token addresses corresponding to '_amounts' and
    /// an array of permits data
    /// @param __recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @custom:data (
    ///        address[] tokens,
    ///        bytes[] permits
    ///    )
    /// @param _sender The address of the sender
    function _allocate(address[] memory __recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveAllocation
    {
        (address[] memory _tokens, bytes[] memory _permits) = abi.decode(_data, (address[], bytes[]));
        uint256 _totalNativeAmount;

        for (uint256 i; i < __recipients.length; i++) {
            if (!_isAcceptedRecipient(__recipients[i])) revert RecipientsExtension_RecipientNotAccepted();

            if (!allowedTokens[_tokens[i]] && !allowedTokens[address(0)]) {
                revert DonationVotingOffchain_TokenNotAllowed();
            }

            if (!DIRECT_TRANSFER) amountAllocated[__recipients[i]][_tokens[i]] += _amounts[i];

            address _recipientAddress = DIRECT_TRANSFER ? _recipients[__recipients[i]].recipientAddress : address(this);

            if (_tokens[i] == NATIVE) {
                _totalNativeAmount += _amounts[i];
            } else {
                _tokens[i].usePermit(_sender, _recipientAddress, _amounts[i], _permits[i]);
            }

            _tokens[i].transferAmountFrom(_sender, _recipientAddress, _amounts[i]);

            emit Allocated(__recipients[i], _sender, _amounts[i], abi.encode(_tokens[i]));
        }

        if (msg.value != _totalNativeAmount) revert ETH_MISMATCH();
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data NOT USED
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        for (uint256 i; i < _recipientIds.length; i++) {
            address _recipientId = _recipientIds[i];

            uint256 _amount = payoutSummaries[_recipientId].amount;
            delete payoutSummaries[_recipientId].amount;

            if (_amount == 0) revert DonationVotingOffchain_NothingToDistribute(_recipientId);
            _poolAmount -= _amount;

            address _recipientAddress = _recipients[_recipientId].recipientAddress;
            IAllo.Pool memory _pool = _ALLO.getPool(_poolId);
            _pool.token.transferAmount(_recipientAddress, _amount);

            emit Distributed(_recipientId, abi.encode(_recipientAddress, _amount, _sender));
        }
    }

    /// @notice Hook called before withdrawing tokens from the pool.
    /// @param _token The address of the token
    /// @param _amount The amount to withdraw
    /// @param _recipient The address to withdraw to
    function _beforeWithdraw(address _token, uint256 _amount, address _recipient) internal virtual override {
        if (block.timestamp <= allocationEndTime + withdrawalCooldown) revert INVALID();
    }

    /// @notice Hook called after increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual override {
        if (block.timestamp > allocationEndTime) revert AllocationExtension_ALLOCATION_HAS_ENDED();
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return If the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool) {
        return _getRecipientStatus(_recipientId) == Status.Accepted;
    }

    /// @notice Returns always true as all addresses are valid allocators
    /// @param _allocator NOT USED
    /// @return Returns always true
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return true;
    }
}
