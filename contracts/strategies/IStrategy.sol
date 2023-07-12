// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IStrategy {

    struct ResultsSummary {
        address recipientId;
        uint votes;
    }
    struct PayoutSummary {
        address recipientId;
        uint amount;
    }

    // add interfaces for all the required functions in the different modules

    function initializeRecipientEligibiilityModule(bytes _data) external;
    function initializeVoterEligibilityModule(bytes _data) external;
    function initializeVotingModule(bytes _data) external;
    function initializeAllocationModule(bytes _data) external;
    function initializeDistributionModule(bytes _data) external;
}
