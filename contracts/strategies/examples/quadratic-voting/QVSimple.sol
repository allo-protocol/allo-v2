// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
// Contracts
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {AllocatorsAllowlistExtension} from "strategies/extensions/allocate/AllocatorsAllowlistExtension.sol";
// Internal Libraries
import {Transfer} from "contracts/core/libraries/Transfer.sol";
import {QVHelper} from "strategies/libraries/QVHelper.sol";

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
contract QVSimple is BaseStrategy, RecipientsExtension, AllocatorsAllowlistExtension {
    using QVHelper for QVHelper.VotingState;
    using Transfer for address;

    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @notice Stores the voting state for QVHelper library
    QVHelper.VotingState internal _votingState;

    /// @notice The maximum voice credits per allocator
    uint256 public maxVoiceCreditsPerAllocator;

    /// @notice The total amount to distribute. Zero if distribution has not started
    uint256 public totalPayoutAmount;

    /// @notice The voice credits allocated for each allocator
    mapping(address => uint256) public voiceCreditsAllocated;

    /// @notice Returns whether or not the recipient has been paid out using their ID
    /// @dev recipientId => paid out
    mapping(address => bool) public paidOut;

    /// ===============================
    /// ========= Constructor =========
    /// ===============================

    constructor(address _allo) RecipientsExtension(_allo, false) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data to initialize the strategy (Must include RecipientInitializeData and QVSimpleInitializeData)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);

        (
            IRecipientsExtension.RecipientInitializeData memory recipientInitializeData,
            QVSimpleInitializeData memory qvSimpleInitializeData
        ) = abi.decode(_data, (IRecipientsExtension.RecipientInitializeData, QVSimpleInitializeData));

        __RecipientsExtension_init(recipientInitializeData);
        __AllocationExtension_init(
            new address[](0),
            qvSimpleInitializeData.allocationStartTime,
            qvSimpleInitializeData.allocationEndTime,
            qvSimpleInitializeData.isUsingAllocationMetadata
        );

        maxVoiceCreditsPerAllocator = qvSimpleInitializeData.maxVoiceCreditsPerAllocator;

        emit Initialized(_poolId, _data);
    }

    /// ======================
    /// ======= Struct =======
    /// ======================

    /// @notice The parameters used to initialize the strategy
    /// @param allocationStartTime The timestamp in seconds for the allocation start time.
    /// @param allocationEndTime The timestamp in seconds for the allocation end time.
    /// @param maxVoiceCreditsPerAllocator The maximumg amount of credits per allocator.
    /// @param isUsingAllocationMetadata Whether the strategy is using allocation metadata.
    struct QVSimpleInitializeData {
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 maxVoiceCreditsPerAllocator;
        bool isUsingAllocationMetadata;
    }

    /// @notice Distribute the tokens to the recipients
    /// @dev The '_sender' must be a pool manager and the allocation must have ended
    /// @param _recipientIds The recipient ids
    /// @param _data NOT USED
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        if (totalPayoutAmount == 0) {
            totalPayoutAmount = poolAmount;
        }

        uint256[] memory payouts = _votingState._getPayout(_recipientIds, totalPayoutAmount);

        IAllo.Pool memory pool = allo.getPool(poolId);

        for (uint256 i; i < payouts.length; ++i) {
            address recipientId = _recipientIds[i];
            Recipient memory recipient = _recipients[recipientId];

            uint256 amount = payouts[i];

            if (paidOut[recipientId] || !_isAcceptedRecipient(recipientId) || amount == 0) {
                revert RECIPIENT_ERROR(recipientId);
            }

            paidOut[recipientId] = true;
            poolAmount -= amount;

            pool.token.transferAmount(recipient.recipientAddress, amount);

            emit Distributed(recipientId, abi.encode(recipient.recipientAddress, amount, _sender));
        }
    }

    /// @notice Allocate voice credits to an array of recipients
    /// @param __recipients The recipients
    /// @param _amounts The amounts of voice credits to allocate
    /// @param _data The data
    /// @param _sender The actual sender of the transaction
    function _allocate(address[] memory __recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        // check that the sender can allocate votes
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        uint256 voiceCreditsToAllocate;

        for (uint256 i = 0; i < __recipients.length; i++) {
            // check the voice credits to allocate is > 0
            if (_amounts[i] == 0) revert INVALID();

            // check that the recipient is accepted
            if (!_isAcceptedRecipient(__recipients[i])) revert RECIPIENT_ERROR(__recipients[i]);

            // sum up the voice credits to allocate
            voiceCreditsToAllocate += _amounts[i];

            emit Allocated(__recipients[i], _sender, voiceCreditsToAllocate, _data);
        }

        // check that the allocator has voice credits left to allocate
        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate, voiceCreditsAllocated[_sender])) revert INVALID();

        _votingState._voteWithVoiceCredits(__recipients, _amounts);

        voiceCreditsAllocated[_sender] += voiceCreditsToAllocate;
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view returns (bool) {
        return _getRecipientStatus(_recipientId) == Status.Accepted;
    }

    /// @notice Checks if the allocator has voice credits left
    /// @param _voiceCreditsToAllocate The voice credits to allocate
    /// @param _allocatedVoiceCredits The allocated voice credits
    /// @return true if the allocator has voice credits left
    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        returns (bool)
    {
        return _voiceCreditsToAllocate + _allocatedVoiceCredits <= maxVoiceCreditsPerAllocator;
    }

    /// @notice Ensure no increase in pool amount is allowed after the distribution starts
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual override {
        if (totalPayoutAmount != 0) {
            revert INVALID();
        }
    }
}
