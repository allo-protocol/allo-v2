// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../core/Allo.sol";
import "../IStrategy.sol";

abstract contract BaseStrategy is IStrategy {
    Allo public immutable allo;

    bytes32 public identityId;
    uint256 public poolId;

    constructor(address _allo) {
        allo = Allo(_allo);
    }

    function initialize(
        bytes32 _identityId,
        uint256 _poolId,
        bytes memory _recipientEligibilityData,
        bytes memory _voterEligibilityData,
        bytes memory _votingData,
        bytes memory _allocationData,
        bytes memory _distributionData
    ) external {
        require(msg.sender == address(allo), "only allo");
        require(_identityId != bytes32(0), "invalid identity id"); // is it the case that identity id will never be 0? any reason it'd be better to use pool?
        require(identityId == bytes32(0), "already initialized");
        identityId = _identityId;
        poolId = _poolId;

        initializeRecipientEligibilityModule(_recipientEligibilityData);
        initializeVoterEligibilityModule(_voterEligibilityData);
        initializeVotingModule(_votingData);
        initializeAllocationModule(_allocationData);
        initializeDistributionModule(_distributionData);
    }

    function poolFunded(uint256 _amount) external;
    // plus maybe some modifiers
}

interface IRecipientEligibilityModule {
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    function initializeRecipientEligibilityModule(bytes _data) external;
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    function allRecipients() public view returns (address[] memory);
}

interface IVoterEligibilityModule {
    function initializeVoterEligibilityModule(bytes _data) external;
    function isValidVoter(address _voter) public view returns (bool); // maybe should be renamed allocator, unless we change to vote below?
}

interface IVotingModule {
    function initializeVotingModule(bytes _data) external;
    function allocate(bytes memory _data, address _sender) external payable; //  is this the right name given module changes?
    function getPayout(address[] memory _recipientId, bytes memory _data)
        external
        view
        returns (PayoutSummary[] memory summaries);
    // maybe readyToPayout? although i think getPayout should just return 0? not sure yet.
}

interface IAllocationModule {
    function initializeAllocationModule(bytes _data) external;
}

interface IDistributionModule {
    function initializeDistributionModule(bytes _data) external;
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}

contract WinnerTakesAll {
    mapping(address => uint256) public votes;

    function allocate(address recipient) external payable {
        votes[recipient] += 1;
    }

    function getResults(address[] memory recipientIds) public view returns (uint256[]) {
        uint256[] memory results = new uint[](recipientIds.length);
        for (uint256 i = 0; i < recipientIds.length; i++) {
            results[i] = votes[recipientIds[i]];
        }
        return results;
    }

    function getPayouts(address[] memory recipientIds) public view returns (PayoutSummary[]) {
        require(recipientIds.length == 0, "pass empty rec, will use all");
        address[] memory recipients = allRecipients();
        uint256[] memory results = getResults(recipients);
        require(recipients.length == results.length);

        uint256 max;
        uint256 winner;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i] > max) {
                max = results[i];
                winner = recipients[i];
            }
        }

        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        for (uint256 i = 0; i < recipientIds.length; i++) {
            if (recipients[i] == winner) {
                payouts[0] = PayoutSummary(recipients[i], address(this).balance);
            }
        }
        return payouts;
    }

    function distribute(address[] memory recipientIds) external {
        PayoutSummary[] memory payouts = getPayouts(recipientIds);
        for (uint256 i = 0; i < payouts.length; i++) {
            payouts[i].payoutAddress.transfer(payouts[i].amount);
        }
    }
}

contract RollingFun {
    mapping(address => uint256) public votes;
    mapping(address => uint256) public claimed;

    function allocate(address recipient, uint256 amount) external payable {
        votes[recipient] += amount;
    }
}
