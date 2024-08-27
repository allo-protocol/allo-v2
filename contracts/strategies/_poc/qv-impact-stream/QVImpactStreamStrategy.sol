// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Libraries
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

// Interfaces
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
// Core Contracts
import {QVBaseStrategy} from "../../qv-base/QVBaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";
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
contract QVImpactStreamStrategy is QVBaseStrategy, Multicall {
    using Transfer for address;

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

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId ID of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    event UpdatedRecipientRegistration(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when the payouts are set
    /// @param payouts The payouts to distribute
    /// @param sender The sender of the transaction
    event PayoutSet(Payout[] payouts, address sender);

    /// ======================
    /// ======= Storage ======
    /// ======================
    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public useRegistryAnchor;

    /// @notice The maximum voice credits per allocator
    uint256 public maxVoiceCreditsPerAllocator;

    /// @notice The details of the allowed allocator
    /// @dev allocator => bool
    mapping(address => bool) public allowedAllocators;

    /// @notice Returns the amount to pay to the recipient
    /// @dev recipientId => payouts
    mapping(address => uint256) public payouts;

    // @notice Returns the proposal bid of the recipient
    /// @dev recipientId => proposalBid
    mapping(address => uint256) public proposalBids;

    bool public payoutSet;

    /// ======================
    /// ======= Struct =======
    /// ======================

    /// @notice The parameters used to initialize the strategy
    struct InitializeParamsSimple {
        bool useRegistryAnchor;
        uint256 maxVoiceCreditsPerAllocator;
        InitializeParams params;
    }

    /// @notice The details of the payout set by the pool managers
    struct Payout {
        address recipientId;
        uint256 amount;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================
    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The ID of the pool
    /// @param _data The initialization data for the strategy
    /// @custom:data (InitializeParamsSimple)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override onlyAllo {
        (InitializeParamsSimple memory initializeParamsSimple) = abi.decode(_data, (InitializeParamsSimple));
        __QVBaseStrategy_init(_poolId, initializeParamsSimple.params);

        maxVoiceCreditsPerAllocator = initializeParamsSimple.maxVoiceCreditsPerAllocator;
        useRegistryAnchor = initializeParamsSimple.useRegistryAnchor;
        emit Initialized(_poolId, _data);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Add allocator array
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocators The allocator address array
    function batchAddAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length;) {
            _addAllocator(_allocators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Add allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocator The allocators address
    function addAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        _addAllocator(_allocator);
    }

    /// @notice Remove allocator array
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocators The allocators address array
    function batchRemoveAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender) {
        uint256 length = _allocators.length;
        for (uint256 i = 0; i < length;) {
            _removeAllocator(_allocators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Remove allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocator The allocator address
    function removeAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        _removeAllocator(_allocator);
    }

    /// @notice Set the payouts to distribute
    /// @dev Only the pool manager(s) can call this function
    /// @param _payouts The payouts to distribute
    function setPayouts(Payout[] memory _payouts) external onlyPoolManager(msg.sender) onlyAfterAllocation {
        if (payoutSet) revert INVALID();
        payoutSet = true;

        uint256 totalAmount;

        uint256 length = _payouts.length;
        for (uint256 i = 0; i < length;) {
            Payout memory payout = _payouts[i];
            uint256 amount = payout.amount;
            address recipientId = payout.recipientId;

            if (amount == 0 || _getRecipientStatus(recipientId) != Status.Accepted) {
                revert RECIPIENT_ERROR(payout.recipientId);
            }

            payouts[recipientId] = amount;
            totalAmount += amount;
            unchecked {
                ++i;
            }
        }

        if (totalAmount > poolAmount) revert INVALID();

        emit PayoutSet(_payouts, msg.sender);
    }

    /// =============================
    /// ==== Internal Functions =====
    /// =============================

    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        IAllo.Pool memory pool = allo.getPool(poolId);
        address poolToken = pool.token;

        uint256 length = _recipientIds.length;
        for (uint256 i = 0; i < length;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            address recipientAddress = recipient.recipientAddress;
            uint256 amount = payouts[recipientId];

            if (amount == 0) revert RECIPIENT_ERROR(recipientId);

            delete payouts[recipientId];

            poolToken.transferAmount(recipientAddress, amount);

            emit Distributed(recipientId, recipientAddress, amount, _sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Add allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocator The allocator address
    function _addAllocator(address _allocator) internal {
        allowedAllocators[_allocator] = true;

        emit AllocatorAdded(_allocator, msg.sender);
    }

    /// @notice Remove allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocator The allocator address
    function _removeAllocator(address _allocator) internal {
        allowedAllocators[_allocator] = false;

        emit AllocatorRemoved(_allocator, msg.sender);
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // check that the sender can allocate votes
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        // check that the recipient has voice credits left to allocate
        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate, allocator.voiceCredits)) revert INVALID();

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
    }

    /// @notice Submit application to pool
    /// @dev The '_data' parameter is encoded as follows:
    ///     - If registryGating is true, then the data is encoded as (address recipientId, address recipientAddress, Metadata metadata)
    ///     - If registryGating is false, then the data is encoded as (address recipientAddress, address registryAnchor, Metadata metadata)
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    /// @return recipientId The ID of the recipient (anchor)
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        returns (address recipientId)
    {
        bool isUsingRegistryAnchor;
        address recipientAddress;
        address registryAnchor;
        uint256 requestedAmount;
        Metadata memory metadata;

        //  @custom:data (address registryAnchor, address recipientAddress, uint256 proposalBid, Metadata metadata)
        (registryAnchor, recipientAddress, requestedAmount, metadata) =
            abi.decode(_data, (address, address, uint256, Metadata));

        // Check if the registry anchor is valid so we know whether to use it or not
        isUsingRegistryAnchor = useRegistryAnchor || registryAnchor != address(0);

        // Ternerary to set the recipient id based on whether or not we are using the 'registryAnchor' or 'recipientAddress'
        recipientId = isUsingRegistryAnchor ? registryAnchor : recipientAddress;

        // Check if the metadata is required and if it is, check if it is valid, otherwise revert
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        Recipient storage recipient = recipients[recipientId];

        if (recipient.recipientAddress == address(0)) {
            emit Registered(recipientId, _data, _sender);
        } else {
            emit UpdatedRecipientRegistration(recipientId, _data, _sender);
        }
        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.useRegistryAnchor = isUsingRegistryAnchor ? true : recipient.useRegistryAnchor;
        recipient.metadata = metadata;
        recipient.recipientStatus = Status.Accepted;
        proposalBids[recipientId] = requestedAmount;
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == Status.Accepted;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allowedAllocators[_allocator];
    }

    /// @notice Checks if the allocator has voice credits left
    /// @param _voiceCreditsToAllocate The voice credits to allocate
    /// @param _allocatedVoiceCredits The allocated voice credits
    /// @return true if the allocator has voice credits left
    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        override
        returns (bool)
    {
        return (_voiceCreditsToAllocate + _allocatedVoiceCredits) <= maxVoiceCreditsPerAllocator;
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the voice credits already cast by an allocator
    /// @param _allocator address of the allocator
    /// @return The voice credits spent by the allocator
    function getVoiceCreditsCastByAllocator(address _allocator) external view returns (uint256) {
        return allocators[_allocator].voiceCredits;
    }

    /// @notice Get the voice credits already cast by an allocator to a recipient
    /// @param _allocator address of the allocator
    /// @param _recipientId ID of the recipient
    /// @return The voice credits spent by the allocator to the recipient
    function getVoiceCreditsCastByAllocatorToRecipient(address _allocator, address _recipientId)
        external
        view
        returns (uint256)
    {
        return allocators[_allocator].voiceCreditsCastToRecipient[_recipientId];
    }

    /// @notice Get the votes already cast by an allocator to a recipient
    /// @param _allocator address of the allocator
    /// @param _recipientId ID of the recipient
    /// @return The votes spent by the allocator to the recipient
    function getVotesCastByAllocatorToRecipient(address _allocator, address _recipientId)
        external
        view
        returns (uint256)
    {
        return allocators[_allocator].votesCastToRecipient[_recipientId];
    }

    /// @notice Get the total votes received for a recipient
    /// @param _recipientId ID of the recipient
    /// @return The total votes received by the recipient
    function getTotalVotesForRecipient(address _recipientId) external view returns (uint256) {
        return recipients[_recipientId].totalVotesReceived;
    }

    /// @notice Checks if a pool is active or not
    /// @return Whether the pool is active or not
    function _isPoolActive() internal view virtual override returns (bool) {
        if (allocationStartTime <= block.timestamp && block.timestamp <= allocationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Get the payout for a single recipient
    /// @param _recipientId The ID of the recipient
    /// @return The payout as a 'PayoutSummary' struct
    function _getPayout(address _recipientId, bytes memory)
        internal
        view
        virtual
        override
        returns (PayoutSummary memory)
    {
        Recipient memory recipient = recipients[_recipientId];
        uint256 amount = payouts[_recipientId];
        return PayoutSummary(recipient.recipientAddress, amount);
    }

    /// @notice Transfer the funds recovered  to the recipient
    /// @dev 'msg.sender' must be pool manager
    /// @param _token The token to transfer
    /// @param _recipient The recipient
    function recoverFunds(address _token, address _recipient) external onlyPoolManager(msg.sender) {
        // Get the amount of the token to transfer, which is always the entire balance of the contract address
        uint256 amount = _token.getBalance(address(this));
        // Transfer the amount to the recipient (pool owner)
        _token.transferAmount(_recipient, amount);
    }
}
