// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract RFPSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool isRegistryIdentity;
        address recipientAddress;
        uint256 proposalBid;
        RecipientStatus recipientStatus;
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
    error EXCEEDING_MAX_BID();
    error MILESTONES_ALREADY_SET();
    error INVALID_METADATA();
    error AMOUNT_TOO_LOW();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event MAX_BID_UPDATED(uint256 maxBid);
    event MILESTONE_SUBMITTED(uint256 milestoneId);
    event MILESTONE_REJECTED(uint256 milestoneId);
    event MILESTONES_SET();

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public registryGating;
    bool public metadataRequired;
    uint256 public maxBid;
    uint256 public upcomingMilestone;
    address public acceptedRecipientId;

    address[] private _recipientIds;
    Milestone[] public milestones;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) private _recipients;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public virtual override {
        (uint256 _maxBid, bool _registryGating, bool _metadataRequired) = abi.decode(_data, (uint256, bool, bool));
        __RFPSimpleStrategy_init(_poolId, _maxBid, _registryGating, _metadataRequired);
    }

    function __RFPSimpleStrategy_init(uint256 _poolId, uint256 _maxBid, bool _registryGating, bool _metadataRequired)
        internal
    {
        __BaseStrategy_init(_poolId);
        registryGating = _registryGating;
        metadataRequired = _metadataRequired;
        _setPoolActive(true);
        _updateMaxBid(_maxBid);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory, bytes memory, address) external view returns (PayoutSummary[] memory) {
        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        payouts[0] = PayoutSummary(acceptedRecipientId, _recipients[acceptedRecipientId].proposalBid);

        return payouts;
    }

    /// @notice Checks if address is elgible allocator
    /// @param _allocator Address of the allocator
    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// @notice Get the status of the milestone
    /// @param _milestoneId Id of the milestone
    function getMilestoneStatus(uint256 _milestoneId) public view returns (RecipientStatus) {
        return milestones[_milestoneId].milestoneStatus;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Set milestones for RFP pool
    /// @param _milestones The milestones to be set
    function setMilestones(Milestone[] memory _milestones) external onlyPoolManager(msg.sender) {
        if (upcomingMilestone != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        uint256 totalAmountPercentage;

        uint256 milestonesLength = _milestones.length;
        for (uint256 i = 0; i < milestonesLength;) {
            totalAmountPercentage += _milestones[i].amountPercentage;
            milestones.push(_milestones[i]);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONE();
        }

        emit MILESTONES_SET();
    }

    /// @notice Submit milestone to RFP pool
    /// @param _metadata The proof of work
    function submitMilestone(Metadata calldata _metadata) external {
        if (acceptedRecipientId != msg.sender && !_isIdentityMember(acceptedRecipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        if (upcomingMilestone > milestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = milestones[upcomingMilestone];
        milestone.metadata = _metadata;
        milestone.milestoneStatus = RecipientStatus.Pending;

        emit MILESTONE_SUBMITTED(upcomingMilestone);
    }

    /// @notice Update max bid for RFP pool
    /// @param _maxBid The max bid to be set
    function updateMaxBid(uint256 _maxBid) external onlyPoolManager(msg.sender) {
        _updateMaxBid(_maxBid);
    }

    /// @notice Reject pending milestone
    /// @param _milestoneId Id of the milestone
    function rejectMilestone(uint256 _milestoneId) external onlyPoolManager(msg.sender) {
        if (milestones[_milestoneId].milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        milestones[_milestoneId].milestoneStatus = RecipientStatus.Rejected;
        emit MILESTONE_REJECTED(_milestoneId);
    }

    /// @notice Withdraw funds from RFP pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        allo.decreasePoolTotalFunding(poolId, _amount);
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit proposal to RFP pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        returns (address recipientId)
    {
        if (acceptedRecipientId != address(0)) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        address recipientAddress;
        bool isRegistryIdentity;
        uint256 proposalBid;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, proposalBid, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, isRegistryIdentity, proposalBid, metadata) =
                abi.decode(_data, (address, bool, uint256, Metadata));
            recipientId = _sender;
            if (isRegistryIdentity && !_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // check if proposal bid is less than max bid
        if (proposalBid > maxBid) {
            revert EXCEEDING_MAX_BID();
        } else if (proposalBid == 0) {
            proposalBid = maxBid;
        }

        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            isRegistryIdentity: registryGating ? true : isRegistryIdentity,
            proposalBid: proposalBid,
            recipientStatus: RecipientStatus.Pending
        });

        _recipients[recipientId] = recipient;
        _recipientIds.push(recipientId);

        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Select recipient for RFP allocation
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyPoolManager(_sender)
    {
        if (acceptedRecipientId != address(0)) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        acceptedRecipientId = abi.decode(_data, (address));

        // update status of acceptedRecipientId to accepted
        if (acceptedRecipientId != address(0)) {
            Recipient storage recipient = _recipients[acceptedRecipientId];

            if (recipient.recipientStatus != RecipientStatus.Pending) {
                revert INVALID_RECIPIENT();
            }

            recipient.recipientStatus = RecipientStatus.Accepted;
            _setPoolActive(false);

            IAllo.Pool memory pool = allo.getPool(poolId);

            emit Allocated(acceptedRecipientId, recipient.proposalBid, pool.token, _sender);
        }
    }

    /// @notice Distribute the upcoming milestone
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (acceptedRecipientId == address(0)) {
            revert INVALID_RECIPIENT();
        }

        if (upcomingMilestone > milestones.length) {
            revert INVALID_MILESTONE();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        Milestone storage milestone = milestones[upcomingMilestone];
        Recipient memory recipient = _recipients[acceptedRecipientId];

        uint256 amount = recipient.proposalBid * milestone.amountPercentage / 1e18;

        allo.decreasePoolTotalFunding(poolId, amount);
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        milestone.milestoneStatus = RecipientStatus.Accepted;
        upcomingMilestone++;

        emit Distributed(acceptedRecipientId, recipient.recipientAddress, amount, _sender);
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

        if (acceptedRecipientId != address(0) && acceptedRecipientId != _recipientId) {
            recipient.recipientStatus =
                recipient.recipientStatus > RecipientStatus.None ? RecipientStatus.Rejected : RecipientStatus.None;
        }
    }

    /// @notice Update max bid for RFP pool
    /// @param _maxBid The max bid to be set
    function _updateMaxBid(uint256 _maxBid) internal {
        if (_maxBid < maxBid) {
            revert AMOUNT_TOO_LOW();
        }
        maxBid = _maxBid;

        emit MAX_BID_UPDATED(maxBid);
    }
}
