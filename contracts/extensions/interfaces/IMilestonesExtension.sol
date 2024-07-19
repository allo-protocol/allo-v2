// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "../../core/libraries/Metadata.sol";

interface IMilestonesExtension {

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when the pool manager attempts to lower the max bid
    error AMOUNT_TOO_LOW();

    /// @notice Thrown when the proposal bid exceeds maximum bid
    error EXCEEDING_MAX_BID();

    /// @notice Thrown when an unauthorized address attempts to submit a milestone
    error INVALID_SUBMITTER();

    /// @notice Thrown when the milestone is invalid
    error INVALID_MILESTONE();

    /// @notice Thrown when the milestone are already approved and cannot be changed
    error MILESTONES_ALREADY_SET();

    /// @notice Thrown when the milestone is not pending
    error MILESTONE_NOT_PENDING();

    /// @notice Thrown when the milestone is pending
    error MILESTONE_PENDING();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the maximum bid is increased.
    /// @param maxBid The new maximum bid
    event MaxBidIncreased(uint256 maxBid);

    /// @notice Emitted when a milestone is submitted.
    /// @param milestoneId Id of the milestone
    event MilestoneSubmitted(uint256 milestoneId);

    /// @notice Emitted for the status change of a milestone.
    /// @param milestoneId Id of the milestone
    /// @param status Status of the milestone
    event MilestoneStatusChanged(uint256 milestoneId, Status status);

    /// @notice Emitted when milestones are set.
    /// @param milestonesLength Count of milestones
    event MilestonesSet(uint256 milestonesLength);

    /// ================================
    /// =========== Enums ==============
    /// ================================

    /// @notice The Status enum that all milestones are based from
    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the milestone
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        Status status;
    }

    /// @notice Stores the details needed for initializing strategy
    struct InitializeParams {
        uint256 maxBid;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The accepted recipient who can submit milestones.
    /// @return acceptedRecipientId Returns the address of the accepted recipient
    function acceptedRecipientId() external view returns (address);

    /// @notice The maximum bid for the RFP pool.
    /// @return maxBid Returns the maximum bid allowed
    function maxBid() external view returns (uint256);

    /// @notice The upcoming milestone index which is to be paid.
    /// @return milestoneIndex Returns the milestone index
    function upcomingMilestone() external view returns (uint256);

    /// @notice This maps recipients to their bids
    /// @param _recipientId ID of the recipient
    /// @return bid Returns the bid
    function bids(address _recipientId) external view returns (uint256);

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the milestone
    /// @param _milestoneId ID of the milestone
    /// @return Milestone Returns the milestone
    function getMilestone(uint256 _milestoneId) external view returns (Milestone memory);

    /// @notice Get the status of the milestone
    /// @param _milestoneId Id of the milestone
    function getMilestoneStatus(uint256 _milestoneId) external view returns (Status);

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update max bid for RFP pool
    /// @dev 'msg.sender' must be a pool manager to update the max bid.
    /// @param _maxBid The max bid to be set
    function increaseMaxBid(uint256 _maxBid) external;

    /// @notice Set the milestones for the acceptedRecipientId.
    /// @dev Emits 'MilestonesSet' event
    /// @param _milestones Milestone[] The milestones to be set
    function setMilestones(Milestone[] memory _milestones) external;

    /// @notice Submit milestone by the acceptedRecipientId.
    /// @dev Emits a 'MilestonesSubmitted()' event.
    /// @param _metadata The proof of work
    function submitUpcomingMilestone(Metadata calldata _metadata) external;

    /// @notice Reject pending milestone submmited by the acceptedRecipientId.
    /// @dev Emits a 'MilestoneStatusChanged()' event.
    /// @param _milestoneStatus ID of the milestone
    function reviewMilestone(Status _milestoneStatus) external;
}