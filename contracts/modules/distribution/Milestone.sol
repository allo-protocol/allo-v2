// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*
This module provides milestone functionality for a given strategy pool of funds.

Examples:
    - Milestones are used to distribute funds to a recipient over time
    - Milestones are used to distribute funds to a recipient based on performance
    - Milestones are used to distribute funds to a recipient based on a schedule

*/

contract Milestone {
    struct MilestoneObject {
        uint256 amountPercentage;
    }
    // Note: think about how to handle this
    // Metadata metadata;
    // RecipientStatus milestoneStatus;

    constructor() {}

    // NOTE:
    /// @notice Adds a milestone
    /// @param _milestone The milestone to add
    function _addMilestone(bytes32 _milestone) internal {}

    // NOTE:
    /// @notice Removes a milestone
    /// @param _milestone The milestone to remove
    function _removeMilestone(bytes32 _milestone) internal {}

    // NOTE:
    /// @notice Updates a milestone
    /// @param _milestone The milestone to update
    function _updateMilestone(bytes32 _milestone) internal {}
}
