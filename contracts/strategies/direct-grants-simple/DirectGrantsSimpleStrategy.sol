// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract DirectGrantsSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        InReview,
        Accepted,
        Rejected
    }

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool isRegistryIdentity;
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
    error INVALID_RECIPIENT();
    error UNAUTHORIZED();
    error INVALID_MILESTONE();
    error MILESTONE_ALREADY_ACCEPTED();
    error MILESTONES_ALREADY_SET();
    error INVALID_REGISTRATION();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event MILESTONE_SUBMITTED(address recipientId, uint256 milestoneId, Metadata metadata);
    event MILESTONE_REJECTED(address recipientId, uint256 milestoneId);
    event MILESTONES_SET(address recipientId);

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public registryGating;
    bool public grantAmountRequired;
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
        (bool _registryGating, bool _grantAmountRequired) = abi.decode(_data, (bool, bool));
        __DirectGrantsSimpleStrategy_init(_poolId, _registryGating, _grantAmountRequired);
    }

    function __DirectGrantsSimpleStrategy_init(uint256 _poolId, bool _registryGating, bool _grantAmountRequired)
        internal
    {
        __BaseStrategy_init(_poolId);
        registryGating = _registryGating;
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
        Recipient memory recipient = _getRecipient(_recipientId);
        if (recipient.recipientStatus == InternalRecipientStatus.Accepted) {
            return RecipientStatus.Accepted;
        } else if (recipient.recipientStatus == InternalRecipientStatus.Rejected) {
            return RecipientStatus.Rejected;
        } else if (recipient.recipientStatus == InternalRecipientStatus.None) {
            return RecipientStatus.None;
        } else {
            return RecipientStatus.Pending;
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
            payouts[i] = PayoutSummary(_recipientIds[i], _recipients[_recipientIds[i]].grantAmount);
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

        emit MILESTONES_SET(_recipientId);
    }

    /// @notice Submit milestone by the recipient
    /// @param _recipientId Id of the recipient
    /// @param _metadata The proof of work
    function submitMilestone(address _recipientId, Metadata calldata _metadata) external {
        if (_recipientId != msg.sender && !_isIdentityMember(_recipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        uint256 milestoneToBeSubmitted = upcomingMilestone[_recipientId];
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        if (milestoneToBeSubmitted > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[milestoneToBeSubmitted];
        milestone.metadata = _metadata;
        milestone.milestoneStatus = RecipientStatus.Pending;

        emit MILESTONE_SUBMITTED(_recipientId, milestoneToBeSubmitted, _metadata);
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
        emit MILESTONE_REJECTED(_recipientId, _milestoneId);
    }

    /// @notice Set the internal status of the recipient to InReview
    /// @param _recipientIds Ids of the recipients
    function setIntenalRecipientStatusToInReview(address[] calldata _recipientIds)
        external
        onlyPoolManager(msg.sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            _recipients[_recipientIds[i]].recipientStatus = InternalRecipientStatus.InReview;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Withdraw funds from pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        allo.decreasePoolTotalFunding(poolId, _amount);
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
        bool isRegistryIdentity;
        uint256 grantAmount;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, isRegistryIdentity, grantAmount, metadata) =
                abi.decode(_data, (address, bool, uint256, Metadata));
            recipientId = _sender;
            if (isRegistryIdentity && !_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (grantAmountRequired && grantAmount == 0) {
            revert INVALID_REGISTRATION();
        }
        if (upcomingMilestone[recipientId] != 0) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            isRegistryIdentity: registryGating ? true : isRegistryIdentity,
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
        (address recipientId, RecipientStatus recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, RecipientStatus, uint256));

        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        Recipient storage recipient = _recipients[recipientId];

        if (recipientStatus == RecipientStatus.Accepted) {
            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = InternalRecipientStatus.Accepted;

            IAllo.Pool memory pool = allo.getPool(poolId);
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
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

        if (milestoneToBeDistributed > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Recipient memory recipient = _recipients[_recipientId];
        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        IAllo.Pool memory pool = allo.getPool(poolId);

        allo.decreasePoolTotalFunding(poolId, amount);
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        milestone.milestoneStatus = RecipientStatus.Accepted;

        upcomingMilestone[_recipientId]++;

        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
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
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }
}
