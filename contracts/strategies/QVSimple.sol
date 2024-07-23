// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {CoreBaseStrategy} from "contracts/strategies/CoreBaseStrategy.sol";
import {RecipientsExtension} from "contracts/extensions/contracts/RecipientsExtension.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {QVHelper} from "contracts/core/libraries/QVHelper.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
// import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";

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
contract QVSimple is CoreBaseStrategy, RecipientsExtension {
    using QVHelper for QVHelper.VotingState;

    /// ======================
    /// ======= Storage ======
    /// ======================

    QVHelper.VotingState internal _votingState;

    /// @notice The maximum voice credits per allocator
    uint256 public maxVoiceCreditsPerAllocator;

    /// @notice The start and end times for allocations
    /// @dev The values will be in milliseconds since the epoch
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice Whether the distribution started or not
    bool public distributionStarted;

    /// @notice The details of the allowed allocator
    /// @dev allocator => bool
    mapping(address => bool) public allowedAllocators;

    mapping(address => uint256) public voiceCreditsAllocated;

    /// @notice Returns whether or not the recipient has been paid out using their ID
    /// @dev recipientId => paid out
    mapping(address => bool) public paidOut;

    constructor(address _allo) CoreBaseStrategy(_allo) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external override {
        __BaseStrategy_init(_poolId);

        (
            IRecipientsExtension.RecipientInitializeData memory recipientInitializeData,
            QVSimpleInitializeData memory qvSimpleInitializeData
        ) = abi.decode(_data, (IRecipientsExtension.RecipientInitializeData, QVSimpleInitializeData));

        __RecipientsExtension_init(recipientInitializeData);
        __QVBaseStrategy_init(qvSimpleInitializeData);

        emit Initialized(_poolId, _data);
    }

    function __QVBaseStrategy_init(QVSimpleInitializeData memory _data) internal {
        maxVoiceCreditsPerAllocator = _data.maxVoiceCreditsPerAllocator;
        allocationStartTime = _data.allocationStartTime;
        allocationEndTime = _data.allocationEndTime;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when an allocator is added
    /// @param allocator The allocator address
    /// @param sender The sender of the transaction
    event AllocatorAdded(address indexed allocator, address sender);

    /// @notice Emitted when an allocator is removed
    /// @param allocator The allocator address
    /// @param sender The sender of the transaction
    event AllocatorRemoved(address indexed allocator, address sender);

    /// ======================
    /// ======= Struct =======
    /// ======================

    /// @notice The parameters used to initialize the strategy
    struct QVSimpleInitializeData {
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 maxVoiceCreditsPerAllocator;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Add allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocator The allocator address
    function addAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = true;

        emit AllocatorAdded(_allocator, msg.sender);
    }

    /// @notice Remove allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocator The allocator address
    function removeAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = false;

        emit AllocatorRemoved(_allocator, msg.sender);
    }

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Check if the allocation is active
    /// @dev Reverts if the allocation is not active
    function _checkOnlyActiveAllocation() internal view virtual {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    function _checkOnlyAfterAllocation() internal view virtual {
        if (block.timestamp <= allocationEndTime) revert ALLOCATION_NOT_ENDED();
    }

    /// @notice Distribute the tokens to the recipients
    /// @dev The '_sender' must be a pool manager and the allocation must have ended
    /// @param _recipientIds The recipient ids
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        uint256[] memory payouts = _votingState._getPayout(_recipientIds, poolAmount);

        for (uint256 i; i < payouts.length;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = _recipients[recipientId];

            uint256 amount = payouts[i];

            if (paidOut[recipientId] || !_isAcceptedRecipient(recipientId) || amount == 0) {
                revert RECIPIENT_ERROR(recipientId);
            }

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            paidOut[recipientId] = true;

            emit Distributed(recipientId, abi.encode(recipient.recipientAddress, amount, _sender));
            unchecked {
                ++i;
            }
        }
        if (!distributionStarted) {
            distributionStarted = true;
        }
    }

    function _allocate(address[] memory __recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        uint256 voiceCreditsAlreadyAllocated = voiceCreditsAllocated[_sender];

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
        }

        // check that the allocator has voice credits left to allocate
        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate, voiceCreditsAlreadyAllocated)) revert INVALID();

        _votingState._voteWithVoiceCredits(__recipients, _amounts);

        // TODO: fix it (recipients is an array and amounts too)
        // emit Allocated(recipientId, _sender, voiceCreditsToAllocate, _data);
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view returns (bool) {
        return _getRecipientStatus(_recipientId) == Status.Accepted;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view returns (bool) {
        return allowedAllocators[_allocator];
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

    function _beforeWithdraw(address, uint256, address) internal override {
        if (block.timestamp <= allocationEndTime + 30 days) {
            revert INVALID();
        }
    }

    function _beforeIncreasePoolAmount(uint256) internal virtual override {
        if (distributionStarted) {
            revert INVALID();
        }
    }
}
