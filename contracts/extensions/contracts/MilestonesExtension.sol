// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IMilestonesExtension} from "../interfaces/IMilestonesExtension.sol";
// Core Contracts
import {CoreBaseStrategy} from "../../strategies/CoreBaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

/// @title Milestone Extension Strategy
abstract contract MilestonesExtension is CoreBaseStrategy, IMilestonesExtension {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The maximum bid allowed.
    uint256 public maxBid;

    /// @notice The upcoming milestone which is to be paid.
    uint256 public upcomingMilestone;

    /// @notice This maps recipients to their bids
    /// @dev 'recipientId' to 'bid'
    mapping(address => uint256) public bids;

    /// @notice Collection of milestones
    Milestone[] internal milestones;

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __MilestonesExtension_init(InitializeParams memory _initializeParams) internal {
        // Set the strategy specific variables
        _increaseMaxBid(_initializeParams.maxBid);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the milestone
    /// @param _milestoneId ID of the milestone
    /// @return Milestone Returns the milestone
    function getMilestone(uint256 _milestoneId) external view returns (Milestone memory) {
        return milestones[_milestoneId];
    }

    /// @notice Get the status of the milestone
    /// @param _milestoneId Id of the milestone
    function getMilestoneStatus(uint256 _milestoneId) external view returns (Status) {
        return milestones[_milestoneId].status;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update max bid for RFP pool
    /// @dev 'msg.sender' must be a pool manager to update the max bid.
    /// @param _maxBid The max bid to be set
    function increaseMaxBid(uint256 _maxBid) external onlyPoolManager(msg.sender) {
        _increaseMaxBid(_maxBid);
    }

    /// @notice Set the milestones.
    /// @dev Emits 'MilestonesSet' event
    /// @param _milestones Milestone[] The milestones to be set
    function setMilestones(Milestone[] memory _milestones) external virtual {
        _validateSetMilestones(msg.sender);
        uint256 totalAmountPercentage;

        // Loop through the milestones and add them to the milestones array
        uint256 milestonesLength = _milestones.length;
        for (uint256 i; i < milestonesLength;) {
            uint256 amountPercentage = _milestones[i].amountPercentage;

            if (amountPercentage == 0) revert MilestonesExtension_INVALID_MILESTONE();

            totalAmountPercentage += amountPercentage;
            _milestones[i].status = Status.None;
            milestones.push(_milestones[i]);

            unchecked {
                i++;
            }
        }

        // Check if the all milestone amount percentage totals to 1e18 (100%)
        if (totalAmountPercentage != 1e18) revert MilestonesExtension_INVALID_MILESTONE();

        emit MilestonesSet(milestonesLength);
    }

    /// @notice Submit milestone by an accepted recipient.
    /// @dev Emits a 'MilestonesSubmitted()' event.
    /// @param _metadata The proof of work
    function submitUpcomingMilestone(Metadata calldata _metadata) external virtual {
        _validateSubmitUpcomingMilestone(msg.sender);

        // Get the milestone and update the metadata and status
        Milestone storage milestone = milestones[upcomingMilestone];
        milestone.metadata = _metadata;

        // Set the milestone status to 'Pending' to indicate that the milestone is submitted
        milestone.status = Status.Pending;

        // Emit event for the milestone
        emit MilestoneSubmitted(upcomingMilestone);
    }

    /// @notice Review a pending milestone submitted by an accepted recipient.
    /// @dev Emits a 'MilestoneStatusChanged()' event.
    /// @param _milestoneStatus New status of the milestone
    function reviewMilestone(Status _milestoneStatus) external virtual {
        _validateReviewMilestone(msg.sender, _milestoneStatus);
        // Check if the milestone status is pending

        milestones[upcomingMilestone].status = _milestoneStatus;

        emit MilestoneStatusChanged(upcomingMilestone, _milestoneStatus);

        if (_milestoneStatus == Status.Accepted) {
            upcomingMilestone++;
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _setProposalBid(address _bidderId, uint256 _proposalBid) internal virtual {
        if (_proposalBid > maxBid) {
            // If the proposal bid is greater than the max bid this will revert
            revert MilestonesExtension_EXCEEDING_MAX_BID();
        } else if (_proposalBid == 0) {
            // If the proposal bid is 0, set it to the max bid
            _proposalBid = maxBid;
        }

        bids[_bidderId] = _proposalBid;
        emit SetBid(_bidderId, _proposalBid);
    }

    function _validateSetMilestones(address _sender) internal virtual {
        _checkOnlyPoolManager(_sender);
        if (milestones.length > 0) {
            if (milestones[0].status != Status.None) revert MilestonesExtension_MILESTONES_ALREADY_SET();
            delete milestones;
        }
    }

    function _validateSubmitUpcomingMilestone(address _sender) internal virtual {
        // Check if the 'msg.sender' is accepted
        if (!_isAcceptedRecipient(_sender)) revert MilestonesExtension_INVALID_SUBMITTER();

        // Check if a submission is ongoing to prevent front-running a milestone review.
        if (milestones[upcomingMilestone].status == Status.Pending) revert MilestonesExtension_MILESTONE_PENDING();
    }

    function _validateReviewMilestone(address _sender, Status _milestoneStatus) internal virtual {
        _checkOnlyPoolManager(_sender);
        if (_milestoneStatus == Status.None) revert MilestonesExtension_INVALID_MILESTONE_STATUS();
        if (milestones[upcomingMilestone].status != Status.Pending) revert MilestonesExtension_MILESTONE_NOT_PENDING();
    }

    /// @notice Increase max bid for RFP pool
    /// @param _maxBid The new max bid to be set
    function _increaseMaxBid(uint256 _maxBid) internal {
        // make sure the new max bid is greater than the current max bid
        if (_maxBid < maxBid) revert MilestonesExtension_AMOUNT_TOO_LOW();

        maxBid = _maxBid;

        // emit the new max mid
        emit MaxBidIncreased(maxBid);
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return If the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool);

    function _getMilestonePayout(address _recipientId, uint256 _milestoneId) internal view virtual returns (uint256) {
        if (!_isAcceptedRecipient(_recipientId)) revert MilestonesExtension_INVALID_RECIPIENT();
        return (bids[_recipientId] * milestones[_milestoneId].amountPercentage) / 1e18;
    }
}
