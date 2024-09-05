// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
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
contract DonationVotingOffchain is BaseStrategy, RecipientsExtension, Native {
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

    /// @notice Emitted when the allocation timestamps are updated
    /// @param allocationStartTime The start time for the allocation period
    /// @param allocationEndTime The end time for the allocation period
    /// @param sender The sender of the transaction
    event AllocationTimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);

    /// ================================
    /// ========== Errors ==============
    /// ================================

    /// @notice Thrown when there is nothing to distribute for the given recipient.
    /// @param recipientId The recipientId to which distribution was attempted.
    error NOTHING_TO_DISTRIBUTE(address recipientId);

    /// @notice Thrown when the timestamps being set or updated don't meet the contracts requirements.
    error INVALID_TIMESTAMPS();

    /// @notice Thrown when a the payout for a recipient is attempted to be overwritten.
    /// @param recipientId The recipientId to which a repeated payout was attempted.
    error PAYOUT_ALREADY_SET(address recipientId);

    /// @notice Thrown when the total payout amount is greater than the pool amount.
    error AMOUNTS_EXCEED_POOL_AMOUNT();

    /// @notice Thrown when the token used was not whitelisted.
    error TOKEN_NOT_ALLOWED();

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

    /// @notice The start time for allocations
    uint64 public allocationStartTime;
    /// @notice The end time for allocations
    uint64 public allocationEndTime;
    /// @notice Cooldown time from allocationEndTime after which the pool manager is allowed to withdraw tokens.
    uint64 public withdrawalCooldown;
    /// @notice amount to be distributed. `totalPayoutAmount` get reduced with each distribution.
    uint256 public totalPayoutAmount;

    /// @notice token -> bool
    mapping(address => bool) public allowedTokens;
    /// @notice recipientId -> PayoutSummary
    mapping(address => PayoutSummary) public payoutSummaries;
    /// @notice recipientId -> token -> amount
    mapping(address => mapping(address => uint256)) public amountAllocated;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if allocation is active
    /// @dev Reverts if allocation is not active
    modifier onlyActiveAllocation() {
        if (block.timestamp < allocationStartTime) revert ALLOCATION_NOT_ACTIVE();
        if (block.timestamp > allocationEndTime) revert ALLOCATION_NOT_ACTIVE();
        _;
    }

    /// @notice Modifier to check if allocation has ended
    /// @dev Reverts if allocation has not ended
    modifier onlyAfterAllocation() {
        if (block.timestamp <= allocationEndTime) revert ALLOCATION_NOT_ENDED();
        _;
    }

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
    ///        address[] _allowedTokens
    ///    )
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (
            RecipientInitializeData memory _recipientExtensionInitializeData,
            uint64 _allocationStartTime,
            uint64 _allocationEndTime,
            uint64 _withdrawalCooldown,
            address[] memory _allowedTokens
        ) = abi.decode(_data, (RecipientInitializeData, uint64, uint64, uint64, address[]));

        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;
        emit AllocationTimestampsUpdated(_allocationStartTime, _allocationEndTime, msg.sender);

        withdrawalCooldown = _withdrawalCooldown;

        if (_allowedTokens.length == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        } else {
            for (uint256 i; i < _allowedTokens.length; i++) {
                allowedTokens[_allowedTokens[i]] = true;
            }
        }

        __BaseStrategy_init(_poolId);
        __RecipientsExtension_init(_recipientExtensionInitializeData);

        emit Initialized(_poolId, _data);
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Sets the start and end dates.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        if (_allocationStartTime > _allocationEndTime) revert INVALID_TIMESTAMPS();
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;
        emit AllocationTimestampsUpdated(allocationStartTime, allocationEndTime, msg.sender);

        _updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    /// @notice Transfers the allocated tokens to recipients.
    /// @dev This function is ignored if DIRECT_TRANSFER is enabled, in which case allocated tokens are not stored
    /// in the contract for later claim but directly sent to recipients in `_allocate()`.
    /// @param _data The data to be decoded
    /// @custom:data (Claim[] _claims)
    function claimAllocation(bytes memory _data) external virtual onlyAfterAllocation {
        if (DIRECT_TRANSFER) revert NOT_IMPLEMENTED();

        (Claim[] memory _claims) = abi.decode(_data, (Claim[]));

        uint256 claimsLength = _claims.length;
        for (uint256 i; i < claimsLength; i++) {
            Claim memory claim = _claims[i];
            uint256 amount = amountAllocated[claim.recipientId][claim.token];
            address recipientAddress = _recipients[claim.recipientId].recipientAddress;

            amountAllocated[claim.recipientId][claim.token] = 0;

            claim.token.transferAmount(recipientAddress, amount);

            emit Claimed(claim.recipientId, amount, claim.token);
        }
    }

    /// @notice Sets the payout amounts to be distributed to.
    /// @param _data The data to be decoded
    /// @custom:data (address[] _recipientIds, uint256[] _amounts)
    function setPayout(bytes memory _data) external virtual onlyPoolManager(msg.sender) onlyAfterAllocation {
        (address[] memory _recipientIds, uint256[] memory _amounts) = abi.decode(_data, (address[], uint256[]));

        uint256 totalAmount;
        for (uint256 i; i < _recipientIds.length; i++) {
            address recipientId = _recipientIds[i];
            if (!_isAcceptedRecipient(recipientId)) revert RECIPIENT_NOT_ACCEPTED();

            PayoutSummary storage payoutSummary = payoutSummaries[recipientId];
            if (payoutSummary.amount != 0) revert PAYOUT_ALREADY_SET(recipientId);

            uint256 amount = _amounts[i];
            totalAmount += amount;

            payoutSummary.amount = amount;
            payoutSummary.recipientAddress = _recipients[recipientId].recipientAddress;

            emit PayoutSet(recipientId, amount);
        }

        totalPayoutAmount += totalAmount;
        if (totalPayoutAmount > poolAmount) revert AMOUNTS_EXCEED_POOL_AMOUNT();
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
        (address[] memory tokens, bytes[] memory permits) = abi.decode(_data, (address[], bytes[]));
        uint256 totalNativeAmount;

        for (uint256 i = 0; i < __recipients.length; i++) {
            if (!_isAcceptedRecipient(__recipients[i])) revert RECIPIENT_NOT_ACCEPTED();

            if (!allowedTokens[tokens[i]] && !allowedTokens[address(0)]) revert TOKEN_NOT_ALLOWED();

            if (!DIRECT_TRANSFER) amountAllocated[__recipients[i]][tokens[i]] += _amounts[i];

            address recipientAddress = DIRECT_TRANSFER ? _recipients[__recipients[i]].recipientAddress : address(this);

            if (tokens[i] == NATIVE) {
                totalNativeAmount += _amounts[i];
            } else {
                tokens[i].usePermit(_sender, recipientAddress, _amounts[i], permits[i]);
            }

            tokens[i].transferAmountFrom(_sender, recipientAddress, _amounts[i]);

            emit Allocated(__recipients[i], _sender, _amounts[i], abi.encode(tokens[i]));
        }

        if (msg.value != totalNativeAmount) revert ETH_MISMATCH();
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
            address recipientId = _recipientIds[i];

            uint256 amount = payoutSummaries[recipientId].amount;
            delete payoutSummaries[recipientId].amount;

            if (amount == 0) revert NOTHING_TO_DISTRIBUTE(recipientId);
            poolAmount -= amount;

            address recipientAddress = _recipients[recipientId].recipientAddress;
            IAllo.Pool memory pool = allo.getPool(poolId);
            pool.token.transferAmount(recipientAddress, amount);

            emit Distributed(recipientId, abi.encode(recipientAddress, amount, _sender));
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
        if (block.timestamp > allocationEndTime) revert POOL_INACTIVE();
    }

    /// @notice Checks if the timestamps are valid.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    function _isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime)
        internal
        view
        virtual
        override
    {
        if (_registrationStartTime > _registrationEndTime) revert INVALID_TIMESTAMPS();
        if (block.timestamp > _registrationStartTime) revert INVALID_TIMESTAMPS();
        // Check consistency with allocation timestamps
        if (_registrationStartTime > allocationStartTime) revert INVALID_TIMESTAMPS();
        if (_registrationEndTime > allocationEndTime) revert INVALID_TIMESTAMPS();
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return If the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool) {
        return _getRecipientStatus(_recipientId) == Status.Accepted;
    }
}
