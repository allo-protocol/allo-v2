// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IStrategy {
    struct ResultsSummary {
        address recipientId;
        uint256 votes;
    }

    struct PayoutSummary {
        address recipientId;
        uint256 amount;
    }

    function initialize(
        bytes32 _identityId,
        uint256 _poolId,
        bytes memory _recipientEligibilityData,
        bytes memory _voterEligibilityData,
        bytes memory _votingData,
        bytes memory _allocationData,
        bytes memory _distributionData
    ) external;
    function skim(address token) external;

    function initializeRecipientEligibiilityModule(bytes _data) external;
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    function allRecipients() public view returns (address[] memory);

    function initializeVoterEligibilityModule(bytes _data) external;
    function isValidVoter(address _voter) public view returns (bool);

    function initializeVotingModule(bytes _data) external;
    function allocate(bytes memory _data, address _sender) external payable;
    function getResults(address[] memory _recipientId, bytes memory _data)
        external
        view
        returns (ResultSummary[] memory);

    function initializeAllocationModule(bytes _data) external;
    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[]);

    function initializeDistributionModule(bytes _data) external;
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
