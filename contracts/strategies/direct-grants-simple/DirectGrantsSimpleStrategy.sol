// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Intefaces
import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

contract DirectGrantsSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        InReview
    }

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        InternalRecipientStatus recipientStatus;
    }

    /// @notice Struct to hold milestone details
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        RecipientStatus milestoneStatus;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error RECIPIENT_ALREADY_ACCEPTED();
    error UNAUTHORIZED();
    error INVALID_MILESTONE();
    error MILESTONE_ALREADY_ACCEPTED();
    error MILESTONES_ALREADY_SET();
    error INVALID_REGISTRATION();
    error ALLOCATION_EXCEEDS_POOL_AMOUNT();
    error INVALID_METADATA();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event RecipientStatusChanged(address recipientId, InternalRecipientStatus status);
    event MilestonesSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, RecipientStatus status);
    event MilestonesSet(address recipientId);

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public registryGating;
    bool public metadataRequired;
    bool public grantAmountRequired;
    uint256 public allocatedGrantAmount;
    address[] private _acceptedRecipientIds;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) private _recipients;
    /// @notice recipientId -> Milestone[]
    mapping(address => Milestone[]) public milestones;
    /// @notice recipientId -> Next Milestone for the recipient
    mapping(address => uint256) public upcomingMilestone;
    /// @notice recipientId -> Total Milestones for the recipient
    mapping(address => uint256) public totalMilestones;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public virtual override {
        (bool _registryGating, bool _metadataRequired, bool _grantAmountRequired) =
            abi.decode(_data, (bool, bool, bool));
        __DirectGrantsSimpleStrategy_init(_poolId, _registryGating, _metadataRequired, _grantAmountRequired);
    }

    function __DirectGrantsSimpleStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        bool _grantAmountRequired
    ) internal {
        __BaseStrategy_init(_poolId);
        registryGating = _registryGating;
        metadataRequired = _metadataRequired;
        grantAmountRequired = _grantAmountRequired;
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
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
        if (internalStatus == InternalRecipientStatus.InReview) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {
        uint256 recipientLength = _recipientIds.length;

        payouts = new PayoutSummary[](recipientLength);

        for (uint256 i = 0; i < recipientLength;) {
            Recipient memory recipient = _getRecipient(_recipientIds[i]);
            payouts[i] = PayoutSummary(recipient.recipientAddress, recipient.grantAmount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if address is elgible allocator
    /// @param _allocator Address of the allocator
    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// @notice Get the status of the milestone of an recipient
    /// @param _recipientId Id of the recipient
    /// @param _milestoneId Id of the milestone
    function getMilestoneStatus(address _recipientId, uint256 _milestoneId) public view returns (RecipientStatus) {
        return milestones[_recipientId][_milestoneId].milestoneStatus;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Set milestones for recipient
    /// @param _recipientId Id of the recipient
    /// @param _milestones The milestones to be set
    function setMilestones(address _recipientId, Milestone[] memory _milestones) external onlyPoolManager(msg.sender) {
        if (upcomingMilestone[_recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        uint256 totalAmountPercentage;

        uint256 milestonesLength = _milestones.length;
        for (uint256 i = 0; i < milestonesLength;) {
            totalAmountPercentage += _milestones[i].amountPercentage;
            milestones[_recipientId].push(_milestones[i]);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONE();
        }

        emit MilestonesSet(_recipientId);
    }

    /// @notice Submit milestone by the recipient
    /// @param _recipientId Id of the recipient
    /// @param _metadata The proof of work
    function submitMilestone(address _recipientId, uint256 _milestoneId, Metadata calldata _metadata) external {
        if (_recipientId != msg.sender && !_isProfileMember(_recipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        Milestone[] storage recipientMilestones = milestones[_recipientId];

        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        if (milestone.milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        milestone.metadata = _metadata;
        milestone.milestoneStatus = RecipientStatus.Pending;

        emit MilestonesSubmitted(_recipientId, _milestoneId, _metadata);
    }

    /// @notice Reject pending milestone of the recipient
    /// @param _recipientId Id of the recipient
    /// @param _milestoneId Id of the milestone
    function rejectMilestone(address _recipientId, uint256 _milestoneId) external onlyPoolManager(msg.sender) {
        Milestone storage milestone = milestones[_recipientId][_milestoneId];
        if (milestone.milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        milestone.milestoneStatus = RecipientStatus.Rejected;
        emit MilestoneStatusChanged(_recipientId, _milestoneId, RecipientStatus.Rejected);
    }

    /// @notice Set the internal status of the recipient to InReview
    /// @param _recipientIds Ids of the recipients
    function setIntenalRecipientStatusToInReview(address[] calldata _recipientIds)
        external
        onlyPoolManager(msg.sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            _recipients[recipientId].recipientStatus = InternalRecipientStatus.InReview;

            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.InReview);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Withdraw funds from pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        poolAmount -= _amount;
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Register to the pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        uint256 grantAmount;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);

            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (grantAmountRequired && grantAmount == 0) {
            revert INVALID_REGISTRATION();
        }
        if (_recipients[recipientId].recipientStatus == InternalRecipientStatus.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            useRegistryAnchor: registryGating ? true : isUsingRegistryAnchor,
            grantAmount: grantAmount,
            metadata: metadata,
            recipientStatus: InternalRecipientStatus.Pending
        });

        _recipients[recipientId] = recipient;

        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Allocate amount to recipent for direct grants
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyPoolManager(_sender)
    {
        (address recipientId, InternalRecipientStatus recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, InternalRecipientStatus, uint256));

        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        Recipient storage recipient = _recipients[recipientId];

        if (
            recipient.recipientStatus != InternalRecipientStatus.Accepted // no need to accept twice
                && recipientStatus == InternalRecipientStatus.Accepted
        ) {
            IAllo.Pool memory pool = allo.getPool(poolId);
            allocatedGrantAmount += grantAmount;

            if (allocatedGrantAmount > pool.amount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }

            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = InternalRecipientStatus.Accepted;

            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Accepted);
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (
            recipient.recipientStatus != InternalRecipientStatus.Rejected // no need to reject twice
                && recipientStatus == InternalRecipientStatus.Rejected
        ) {
            recipient.recipientStatus == InternalRecipientStatus.Rejected;
            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Rejected);
        }
    }

    /// @notice Distribute the upcoming milestone
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            _distributeUpcomingMilestone(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    function _distributeUpcomingMilestone(address _recipientId, address _sender) private {
        uint256 milestoneToBeDistributed = upcomingMilestone[_recipientId];
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        Recipient memory recipient = _recipients[_recipientId];
        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        if (
            milestoneToBeDistributed > recipientMilestones.length
                || milestone.milestoneStatus != RecipientStatus.Pending
        ) {
            revert INVALID_MILESTONE();
        }

        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        IAllo.Pool memory pool = allo.getPool(poolId);

        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        milestone.milestoneStatus = RecipientStatus.Accepted;

        upcomingMilestone[_recipientId]++;

        emit MilestoneStatusChanged(_recipientId, milestoneToBeDistributed, RecipientStatus.Accepted);
        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @notice Check if sender is profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_anchor);
        return registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }
}
