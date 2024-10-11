// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
import {Metadata} from "contracts/core/libraries/Metadata.sol";

interface IMilestonesExtension {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the maximum bid is increased.
    /// @param maxBid The new maximum bid
    event MaxBidIncreased(uint256 maxBid);

    /// @notice Emitted when a bidder places a bid.
    /// @param bidderId The address of the bidder
    /// @param newBid The bid amount
    event SetBid(address indexed bidderId, uint256 newBid);

    /// @notice Emitted when a milestone is submitted.
    /// @param milestoneId Id of the milestone
    event MilestoneSubmitted(uint256 milestoneId);

    /// @notice Emitted for the status change of a milestone.
    /// @param milestoneId Id of the milestone
    /// @param status Status of the milestone
    event MilestoneStatusChanged(uint256 indexed milestoneId, MilestoneStatus status);

    /// @notice Emitted when milestones are set.
    /// @param milestonesLength Count of milestones
    event MilestonesSet(uint256 milestonesLength);

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when the pool manager attempts to lower the max bid
    error MilestonesExtension_AmountTooLow();

    /// @notice Thrown when the proposal bid exceeds maximum bid
    error MilestonesExtension_ExceedingMaxBid();

    /// @notice Thrown when a recipient is not accepted
    error MilestonesExtension_InvalidRecipient();

    /// @notice Thrown when an unauthorized address attempts to submit a milestone
    error MilestonesExtension_InvalidSubmitter();

    /// @notice Thrown when the milestone is invalid
    error MilestonesExtension_InvalidMilestone();

    /// @notice Thrown when the new milestone status being reviewed is invalid
    error MilestonesExtension_InvalidMilestoneStatus();

    /// @notice Thrown when the milestone are already approved and cannot be changed
    error MilestonesExtension_MilestonesAlreadySet();

    /// @notice Thrown when the milestone is not pending
    error MilestonesExtension_MilestoneNotPending();

    /// @notice Thrown when the milestone is pending
    error MilestonesExtension_MilestonePending();

    /// ================================
    /// =========== Enums ==============
    /// ================================

    /// @notice The Status enum that all milestones are based from
    enum MilestoneStatus {
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
    /// @param amountPercentage The percentage of the bid assign to the milestone
    /// @param metadata The metadata associated to the milestone
    /// @param status The status of the milestone
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        MilestoneStatus status;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The maximum bid allowed
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
    /// @return MilestoneStatus Returns the milestone status
    function getMilestoneStatus(uint256 _milestoneId) external view returns (MilestoneStatus);

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update max bid
    /// @dev 'msg.sender' must be a pool manager to update the max bid.
    /// @param _maxBid The max bid to be set
    function increaseMaxBid(uint256 _maxBid) external;

    /// @notice Set the milestones.
    /// @dev Emits 'MilestonesSet' event
    /// @param _milestones Milestone[] The milestones to be set
    function setMilestones(Milestone[] memory _milestones) external;

    /// @notice Submit milestone by an accepted recipient.
    /// @dev Emits a 'MilestonesSubmitted()' event.
    /// @param _recipientId The recipient id
    /// @param _metadata The proof of work
    function submitUpcomingMilestone(address _recipientId, Metadata calldata _metadata) external;

    /// @notice Reject pending milestone submmited by an accepted recipient.
    /// @dev Emits a 'MilestoneStatusChanged()' event.
    /// @param _milestoneStatus ID of the milestone
    function reviewMilestone(MilestoneStatus _milestoneStatus) external;
}
