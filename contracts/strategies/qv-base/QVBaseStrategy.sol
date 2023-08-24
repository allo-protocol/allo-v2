// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

abstract contract QVBaseStrategy is BaseStrategy {
    /// ======================
    /// ======= Errors ======
    /// ======================

    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error INVALID();
    error INVALID_METADATA();
    error RECIPIENT_ERROR(address recipientId);
    error REGISTRATION_NOT_ACTIVE();
    error UNAUTHORIZED();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event RecipientStatusUpdated(address indexed recipientId, InternalRecipientStatus status, address sender);
    event TimestampsUpdated(
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime,
        address sender
    );

    event Allocated(address indexed recipientId, uint256 votes, address allocator);
    event Reviewed(address indexed recipientId, InternalRecipientStatus status, address sender);

    /// ======================
    /// ======= Storage ======
    /// ======================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        InternalRecipientStatus recipientStatus;
        uint256 totalVotesReceived;
    }

    struct Allocator {
        uint256 voiceCredits;
        mapping(address => uint256) voiceCreditsCastToRecipient;
        mapping(address => uint256) votesCastToRecipient;
    }

    bool public registryGating;
    bool public metadataRequired;
    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    uint256 public totalRecipientVotes;
    uint256 public reviewThreshold;

    IRegistry private _registry;

    /// @notice recipientId => Recipient
    mapping(address => Recipient) public recipients;
    /// @notice allocator address => Allocator
    mapping(address => Allocator) public allocators;

    /// @notice recipientId => paid out
    mapping(address => bool) public paidOut;

    // recipientId -> status -> count
    mapping(address => mapping(InternalRecipientStatus => uint256)) public reviewsByStatus;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    modifier onlyActiveRegistration() {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyActiveAllocation() {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ====================================
    /// =========== Initialize =============
    /// ====================================

    function initialize(uint256 _poolId, bytes memory _data) external virtual;

    /// @dev Internal initialize function
    /// @param _poolId The pool id
    /// @param _registryGating Whether or not to use registry gating
    /// @param _metadataRequired Whether or not metadata is required
    /// @param _registrationStartTime The registration start time
    /// @param _registrationEndTime The registration end time
    /// @param _allocationStartTime The allocation start time
    /// @param _allocationEndTime The allocation end time
    function __QVBaseStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        uint256 _reviewThreshold,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __BaseStrategy_init(_poolId);

        registryGating = _registryGating;
        metadataRequired = _metadataRequired;
        _registry = allo.getRegistry();

        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        reviewThreshold = _reviewThreshold;

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @param _recipientId Id of the recipient
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = _getRecipient(_recipientId).recipientStatus;
        if (internalStatus == InternalRecipientStatus.Appealed) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// @notice Returns status of the pool
    function _isPoolActive() internal view virtual override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Review recipient application
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, InternalRecipientStatus[] calldata _recipientStatuses)
        external
        virtual
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < recipientLength;) {
            InternalRecipientStatus recipientStatus = _recipientStatuses[i];
            address recipientId = _recipientIds[i];
            if (recipientStatus == InternalRecipientStatus.None || recipientStatus == InternalRecipientStatus.Appealed)
            {
                revert RECIPIENT_ERROR(recipientId);
            }

            reviewsByStatus[recipientId][recipientStatus]++;

            if (reviewsByStatus[recipientId][recipientStatus] >= reviewThreshold) {
                Recipient storage recipient = recipients[recipientId];
                recipient.recipientStatus = recipientStatus;

                emit RecipientStatusUpdated(recipientId, recipientStatus, address(0));
            }

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit application to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;

        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        Recipient storage recipient = recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = registryGating ? true : isUsingRegistryAnchor;

        // NOTE: do we need this? the status is not ever set to anything but None
        // on creation? Shouldn't we be setting the status on review or setting it to
        // Pending? Will it ever be Rejected when this is called? @thelostone-mc @KurtMerbeth
        if (recipient.recipientStatus == InternalRecipientStatus.Rejected) {
            recipient.recipientStatus = InternalRecipientStatus.Appealed;
            emit Appealed(recipientId, _data, _sender);
        } else {
            recipient.recipientStatus = InternalRecipientStatus.Pending;
            emit Registered(recipientId, _data, _sender);
        }
    }

    /// @notice Distribute the tokens to the recipients
    /// @param _recipientIds The recipient ids
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        uint256 payoutLength = _recipientIds.length;
        for (uint256 i = 0; i < payoutLength;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            PayoutSummary memory payout = _getPayout(recipientId, "");
            uint256 amount = payout.amount;

            if (paidOut[recipientId] || !_isAcceptedRecipient(recipientId) || amount == 0) {
                revert RECIPIENT_ERROR(recipientId);
            }

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            paidOut[recipientId] = true;

            emit Distributed(recipientId, recipient.recipientAddress, amount, _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if sender is profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return recipients[_recipientId];
    }

    /// ====================================
    /// ============ QV Helper ==============
    /// ====================================

    /// @notice Calculate the square root of a number (Babylonian method)
    /// @param x The number
    /// @return y The square root
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _qv_allocate(
        Allocator storage _allocator,
        Recipient storage _recipient,
        address _recipientId,
        uint256 _voiceCreditsToAllocate,
        address _sender
    ) internal onlyActiveAllocation {
        // check the voiceCreditsToAllocate is > 0
        if (_voiceCreditsToAllocate == 0) {
            revert INVALID();
        }

        uint256 creditsCastToRecipient = _allocator.voiceCreditsCastToRecipient[_recipientId];
        uint256 votesCastToRecipient = _allocator.votesCastToRecipient[_recipientId];

        uint256 totalCredits = _voiceCreditsToAllocate + creditsCastToRecipient;
        uint256 voteResult = _sqrt(totalCredits * 1e18);
        voteResult -= votesCastToRecipient;
        totalRecipientVotes += voteResult;
        _recipient.totalVotesReceived += voteResult;

        _allocator.voiceCreditsCastToRecipient[_recipientId] += totalCredits;
        _allocator.votesCastToRecipient[_recipientId] += voteResult;

        emit Allocated(_recipientId, voteResult, _sender);
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool);

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool);

    /// @notice Checks if the allocator has voice credits left
    /// @param _voiceCreditsToAllocate The voice credits to allocate
    /// @param _allocatedVoiceCredits The allocated voice credits
    /// @return true if the allocator has voice credits left
    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        virtual
        returns (bool);

    /// @notice Get the payout for a single recipient
    /// @param _recipientId The recipient id
    /// @return The payout as a PayoutSummary struct
    function _getPayout(address _recipientId, bytes memory)
        internal
        view
        virtual
        override
        returns (PayoutSummary memory)
    {
        Recipient memory recipient = recipients[_recipientId];

        // Calculate the payout amount based on the percentage of total votes
        uint256 amount;
        if (paidOut[_recipientId] || totalRecipientVotes == 0) {
            amount = 0;
        } else {
            amount = poolAmount * recipient.totalVotesReceived / totalRecipientVotes;
        }
        return PayoutSummary(recipient.recipientAddress, amount);
    }
}
