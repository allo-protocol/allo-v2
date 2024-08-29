
# Milestones Extension

The `MilestonesExtension` contract is designed for managing milestones within a funding strategy. It supports setting, submitting, and reviewing milestones, allowing for structured progress tracking and funding disbursement.

## Key Features

- **Milestone Management**: Define and set milestones with specific percentage allocations.
- **Bid Handling**: Manage and validate bids for recipients, including setting a maximum bid.
- **Submission and Review**: Recipients can submit milestones, which are then reviewed and approved by a pool manager.

## Key Functions

- `setMilestones(Milestone[] memory _milestones)`: Sets and validates milestones.
- `submitUpcomingMilestone(address _recipientId, Metadata calldata _metadata)`: Allows recipients to submit a milestone for review.
- `reviewMilestone(MilestoneStatus _milestoneStatus)`: Reviews and updates the status of the submitted milestone.
- `increaseMaxBid(uint256 _maxBid)`: Updates the maximum allowable bid.

## Events

- `MilestonesSet(uint256 milestonesLength)`: Emitted when milestones are set.
- `MilestoneSubmitted(uint256 milestoneId)`: Emitted when a milestone is submitted.
- `MilestoneStatusChanged(uint256 milestoneId, MilestoneStatus newStatus)`: Emitted when a milestone’s status is changed.
- `SetBid(address bidderId, uint256 bidAmount)`: Emitted when a bid is set.
- `MaxBidIncreased(uint256 newMaxBid)`: Emitted when the maximum bid amount is increased.

## Usage

1. **Initialization**: Initialize with the desired maximum bid.
2. **Set Milestones**: Define and set milestones using `setMilestones`.
3. **Submit Milestone**: Recipients submit milestones for review.
4. **Review Milestones**: Pool managers review and approve or reject milestones.

For more details, refer to the Solidity source code and contract comments.
