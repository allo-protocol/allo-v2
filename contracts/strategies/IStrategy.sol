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

    function initializeRecipientEligibiilityModule(bytes _data) external;
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    function allRecipients() public view returns (address[] memory);

    function initializeVoterEligibilityModule(bytes _data) external;
    function isValidVoter(address _voter) public view returns (bool);

    function initializeVotingModule(bytes _data) external;
    function allocate(bytes memory _data, address _sender) external payable;
    function getResults(address[] memory _recipientId, bytes memory _data) external view returns (ResultSummary[] memory);

    function initializeAllocationModule(bytes _data) external;
    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[])

    function initializeDistributionModule(bytes _data) external;
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
