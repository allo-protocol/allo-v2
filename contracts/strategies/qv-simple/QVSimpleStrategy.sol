// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

contract QVSimpleStrategy is BaseStrategy {
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
        uint256 totalVotes;
    }

    struct Allocator {
        uint256 voiceCredits;
        mapping(address => uint256) voiceCreditsCastToRecipient;
        mapping(address => uint256) votesCastToRecipient;
    }

    bool public registryGating;
    bool public metadataRequired;

    uint256 public totalRecipientVotes;
    uint256 public maxVoiceCreditsPerAllocator;

    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    // recipientId => Recipient
    mapping(address => Recipient) public recipients;
    // allocator address => Allocator
    mapping(address => Allocator) public allocators;
    // allocator => bool
    mapping(address => bool) public allowedAllocators;
    // recipientId => paid out
    mapping(address => bool) public paidOut;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    modifier onlyActiveRegistration() {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyActiveAllocation() {
        if (allocationStartTime <= block.timestamp && block.timestamp <= allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp <= allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public override {
        (
            bool _registryGating,
            bool _metadataRequired,
            uint256 _maxVoiceCreditsPerAllocator,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, uint256));
        __QVSimpleStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            _maxVoiceCreditsPerAllocator,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
    }

    /// @dev Internal initialize function that sets the poolId in the base strategy
    function __QVSimpleStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        uint256 _maxVoiceCreditsPerAllocator,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __BaseStrategy_init(_poolId);

        registryGating = _registryGating;
        metadataRequired = _metadataRequired;

        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        maxVoiceCreditsPerAllocator = _maxVoiceCreditsPerAllocator;
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;
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
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = _getRecipient(_recipientId).recipientStatus;
        if (internalStatus == InternalRecipientStatus.Appealed) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view returns (bool) {
        return allowedAllocators[_allocator];
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Review recipient application
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, InternalRecipientStatus[] calldata _recipientStatuses)
        external
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

            Recipient storage recipient = recipients[recipientId];

            recipient.recipientStatus = recipientStatus;

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Get the payouts for the recipients
    /// @param _recipientIds The recipient ids
    /// @return The payouts as an array of PayoutSummary structs
    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        public
        view
        override
        returns (PayoutSummary[] memory)
    {
        PayoutSummary[] memory payouts = new PayoutSummary[](_recipientIds.length);
        uint256 recipientLength = _recipientIds.length;
        uint256 poolAmount = allo.getPool(poolId).amount;

        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            Recipient memory recipient = recipients[recipientId];

            // Calculate the payout amount based on the percentage of total votes
            uint256 amount = paidOut[recipientId] ? 0 : (poolAmount * recipient.totalVotes / totalRecipientVotes);

            payouts[i] = PayoutSummary(recipient.recipientAddress, amount);

            unchecked {
                i++;
            }
        }

        return payouts;
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
            _registrationStartTime > registrationStartTime || block.timestamp > _registrationStartTime
                || _registrationStartTime > _registrationEndTime || _registrationStartTime > _allocationStartTime
                || _allocationStartTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit application to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        bool useRegistryAnchor;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            if (!_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, useRegistryAnchor, metadata) = abi.decode(_data, (address, bool, Metadata));
            recipientId = _sender;
            if (useRegistryAnchor && !_isIdentityMember(recipientId, _sender)) {
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
        recipient.useRegistryAnchor = registryGating ? true : useRegistryAnchor;

        if (recipient.recipientStatus == InternalRecipientStatus.Rejected) {
            recipient.recipientStatus = InternalRecipientStatus.Appealed;
            emit Appealed(recipientId, _data, _sender);
        } else {
            recipient.recipientStatus = InternalRecipientStatus.Pending;
            emit Registered(recipientId, _data, _sender);
        }
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // check the voiceCreditsToAllocate is > 0
        if (voiceCreditsToAllocate <= 0) {
            revert INVALID();
        }

        // check the time periods for allocation
        if (block.timestamp < allocationStartTime || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }

        // check that the sender can allocate votes
        if (!allowedAllocators[_sender]) {
            revert UNAUTHORIZED();
        }

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (voiceCreditsToAllocate + allocator.voiceCredits > maxVoiceCreditsPerAllocator) {
            revert();
        }

        uint256 creditsCastToRecipient = allocator.voiceCreditsCastToRecipient[recipientId];
        uint256 votesCastToRecipient = allocator.votesCastToRecipient[recipientId];

        uint256 totalCredits = voiceCreditsToAllocate + creditsCastToRecipient;
        uint256 voteResult = _sqrt(totalCredits * 1e18);
        voteResult -= votesCastToRecipient;
        totalRecipientVotes += voteResult;
        recipient.totalVotes += voteResult;

        allocator.voiceCreditsCastToRecipient[recipientId] += totalCredits;
        allocator.votesCastToRecipient[recipientId] += voteResult;

        emit Allocated(_sender, voteResult, address(0), msg.sender);
    }

    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        PayoutSummary[] memory payouts = getPayouts(_recipientIds, "", _sender);

        uint256 payoutLength = payouts.length;
        for (uint256 i; i < payoutLength;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            if (recipient.recipientStatus != InternalRecipientStatus.Accepted) {
                revert RECIPIENT_ERROR(recipientId);
            }

            uint256 amount = payouts[i].amount;

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            paidOut[recipientId] = true;

            emit Distributed(recipientId, recipient.recipientAddress, amount, _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if sender is identity owner or member
    /// @param _anchor Anchor of the identity
    /// @param _sender The sender of the transaction
    function _isIdentityMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isOwnerOrMemberOfIdentity(identity.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return recipients[_recipientId];
    }

    /// ====================================
    /// ============ QV Helper ==============
    /// ====================================

    function _calculateVotes(uint256 amount) internal pure returns (uint256) {
        return _sqrt(amount);
    }

    function _calculatePayoutAmount(uint256 totalVotes, uint256 recipientVotes) internal pure returns (uint256) {
        // Calculate the percentage of total votes
        uint256 percentage = (recipientVotes * 100) / totalVotes;
        // Calculate the payout amount based on the percentage of total pool funds
        // ...

        return percentage;
    }

    /// @notice Calculate the square root of a number (Babylonian method)
    /// @param x The number
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculate the square root of a number in wei
    /// @param weiX The number in wei
    // Note: overflow is not checked and can occur if weiX is too large
    function _sqrtWei(uint256 weiX) internal pure returns (uint256 weiY) {
        // Convert to "fixed-point" representation with 18 decimal places
        uint256 x = weiX * 1e18;
        uint256 y = _sqrt(x);
        // Convert back to wei
        return y / 1e9;
    }
}
