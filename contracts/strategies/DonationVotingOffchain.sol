// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
// Interfaces
import {IAllo} from "../core/interfaces/IAllo.sol";
// Core Contracts
import {CoreBaseStrategy} from "./CoreBaseStrategy.sol";
import {RecipientsExtension} from "../extensions/contracts/RecipientsExtension.sol";
// Internal Libraries
import {Native} from "../core/libraries/Native.sol";

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
contract DonationVotingOffchain is CoreBaseStrategy, RecipientsExtension {
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
    error NOTHING_TO_DISTRIBUTE(address recipientId);

    /// @notice Thrown when the timestamps being set or updated don't meet the contracts requirements.
    error INVALID_TIMESTAMPS();

    /// @notice Thrown when a the payout for a recipient is attempted to be overwritten.
    error PAYOUT_ALREADY_SET(address recipientId);

    /// @notice Thrown when the total payout amount is greater than the pool amount.
    error AMOUNTS_EXCEED_POOL_AMOUNT();

    /// @notice Thrown when the token used was not whitelisted.
    error TOKEN_NOT_ALLOWED();

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Payout summary struct to hold the payout data
    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// @notice Struct to hold details of the allocations to claim
    struct Claim {
        address recipientId;
        address token;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The start and end times for allocations
    uint64 public allocationStartTime;
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

    /// @notice Claim allocated tokens
    /// @param _claims Claims to be claimed
    function claimAllocation(Claim[] calldata _claims) external onlyAfterAllocation {
        uint256 claimsLength = _claims.length;
        for (uint256 i; i < claimsLength; i++) {
            Claim calldata claim = _claims[i];
            uint256 amount = amountAllocated[claim.recipientId][claim.token];
            address recipientAddress = _recipients[claim.recipientId].recipientAddress;

            amountAllocated[claim.recipientId][claim.token] = 0;

            _transferAmount(claim.token, recipientAddress, amount);

            emit Claimed(claim.recipientId, amount, claim.token);
        }
    }

    /// @notice Set payout for the recipients
    /// @param _recipientIds Ids of the recipients
    /// @param _amounts Amounts to be paid out
    function setPayout(address[] memory _recipientIds, uint256[] memory _amounts)
        external
        onlyPoolManager(msg.sender)
        onlyAfterAllocation
    {
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
    /// @dev The encoded '_data' is an array of token addresses corresponding to the _amounts array.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveAllocation
    {
        (address[] memory tokens) = abi.decode(_data, (address[]));
        uint256 totalNativeAmount;

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (!_isAcceptedRecipient(_recipients[i])) revert RECIPIENT_NOT_ACCEPTED();

            if (!allowedTokens[tokens[i]] && !allowedTokens[address(0)]) {
                revert TOKEN_NOT_ALLOWED();
            }

            // Update the total payout amount for the claim and the total claimable amount
            amountAllocated[_recipients[i]][tokens[i]] += _amounts[i];

            if (tokens[i] == NATIVE) {
                totalNativeAmount += _amounts[i];
            } else {
                SafeTransferLib.safeTransferFrom(tokens[i], _sender, address(this), _amounts[i]);
            }

            emit Allocated(_recipients[i], _sender, _amounts[i], abi.encode(tokens[i]));
        }

        if (msg.value != totalNativeAmount) revert AMOUNT_MISMATCH();
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
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
            _transferAmount(pool.token, recipientAddress, amount);

            emit Distributed(recipientId, abi.encode(recipientAddress, amount, _sender));
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
