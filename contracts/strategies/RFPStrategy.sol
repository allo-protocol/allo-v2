// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../core/IAllo.sol";
import {IRegistry} from "../core/IRegistry.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {Metadata} from "../core/libraries/Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract RFPStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
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
    error NO_ACCEPTED_RECIPIENT();
    error UNAUTHORIZED();
    error INVALID_MILESTONE();
    error MILESTONE_ALREADY_ACCEPTED();
    error EXCEEDING_MAX_BID();

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
    uint256 public maxBid;
    uint256 public upcomingMilestone;
    address public acceptedRecipientId;

    address[] private _recipientIds;
    Milestone[] public milestones;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) public recipients;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        super.initialize(_poolId, _data);

        (maxBid, registryGating) = abi.decode(_data, (uint256, bool));

        emit MAX_BID_UPDATED(maxBid);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) public view override returns (RecipientStatus status) {
        return recipients[_recipientId].recipientStatus;
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory, bytes memory, address) external view returns (PayoutSummary[] memory) {
        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        payouts[0] = PayoutSummary(acceptedRecipientId, recipients[acceptedRecipientId].proposalBid);

        return payouts;
    }

    /// @notice Checks if address is elgible allocator
    /// @param _allocator Address of the allocator
    function isValidAllocator(address _allocator) public view returns (bool) {
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
        uint256 milestonesLength = _milestones.length;
        for (uint256 i = 0; i < milestonesLength;) {
            milestones.push(_milestones[i]);

            unchecked {
                i++;
            }
        }

        emit MILESTONES_SET();
    }

    /// @notice Submit milestone to RFP pool
    /// @param _metadata The proof of work
    function submitMilestone(Metadata calldata _metadata) external {
        if (acceptedRecipientId != msg.sender && !_isIdentityManager(acceptedRecipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        if (upcomingMilestone > milestones.length) {
            revert INVALID_MILESTONE();
        }

        milestones[upcomingMilestone].metadata = _metadata;
        milestones[upcomingMilestone].milestoneStatus = RecipientStatus.Pending;

        emit MILESTONE_SUBMITTED(upcomingMilestone);
    }

    /// @notice Update max bid for RFP pool
    /// @param _maxBid The max bid to be set
    function updateMaxBid(uint256 _maxBid) external onlyPoolManager(msg.sender) {
        maxBid = _maxBid;

        emit MAX_BID_UPDATED(maxBid);
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

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit proposal to RFP pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address recipientId) {
        if (acceptedRecipientId != address(0)) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        address recipientAddress;
        uint256 proposalBid;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, proposalBid, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isIdentityManager(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, proposalBid, metadata) = abi.decode(_data, (address, uint256, Metadata));
            recipientId = _sender;
        }

        // check if proposal bid is less than max bid
        if (proposalBid > maxBid) {
            revert EXCEEDING_MAX_BID();
        } else if (proposalBid == 0) {
            proposalBid = maxBid;
        }

        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            proposalBid: proposalBid,
            recipientStatus: RecipientStatus.Pending
        });

        recipients[recipientId] = recipient;
        _recipientIds.push(recipientId);

        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Select recipient for RFP allocation
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender) internal override nonReentrant onlyPoolManager(_sender) {
        if (acceptedRecipientId != address(0)) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        acceptedRecipientId = abi.decode(_data, (address));

        uint256 _recipientsCounter = _recipientIds.length;
        for (uint256 i = 0; i < _recipientsCounter;) {
            // update status of all other recipients to rejected
            address recipientId = _recipientIds[i];
            if (recipientId != acceptedRecipientId) {
                recipients[recipientId].recipientStatus = RecipientStatus.Rejected;
            }

            unchecked {
                i++;
            }
        }

        // update status of acceptedRecipientId to accepted
        if (acceptedRecipientId != address(0)) {
            Recipient storage recipient = recipients[acceptedRecipientId];
            recipient.recipientStatus = RecipientStatus.Accepted;

            IAllo.Pool memory pool = allo.getPool(poolId);

            emit Allocated(acceptedRecipientId, recipient.proposalBid, pool.token, _sender);
        }
    }

    function _distribute(address[] memory, bytes memory, address _sender) internal override onlyPoolManager(_sender) {
        if (acceptedRecipientId == address(0)) {
            revert NO_ACCEPTED_RECIPIENT();
        }

        if (upcomingMilestone > milestones.length) {
            revert INVALID_MILESTONE();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        Milestone storage milestone = milestones[upcomingMilestone];
        Recipient memory recipient = recipients[acceptedRecipientId];

        uint256 amount = recipient.proposalBid * milestone.amountPercentage / 1e18;

        allo.decreasePoolTotalFunding(poolId, amount);
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        milestone.milestoneStatus = RecipientStatus.Accepted;
        upcomingMilestone++;

        emit Distributed(acceptedRecipientId, recipient.recipientAddress, amount, _sender);
    }

    function _isIdentityManager(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isOwnerOrMemberOfIdentity(identity.id, _sender);
    }
}
