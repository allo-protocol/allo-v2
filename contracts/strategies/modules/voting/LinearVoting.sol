// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IVotingModule} from "./IVotingModule.sol";

contract LinearVoting is IVotingModule {
    mapping(address => uint256) public votesReceived;
    mapping(address => bool) public hasVoted;
    uint256 startTime;
    uint256 endTime;

    function initializeVotingModule(bytes _data) external {
        (startTime, endTime) = abi.decode(_data, (uint256, uint256));
    }

    function allocate(bytes memory _data, address _sender) external payable {
        require(!hasVoted[_sender], "already voted");
        require(block.timestamp >= startTime, "voting not started");
        require(block.timestamp <= endTime, "voting ended");
        address vote = abi.decode(_data, (address));
        votesReceived[vote]++;
        hasVoted[_sender] = true;
    }

    function getResults(address[] memory _recipientId, bytes memory _data)
        external
        view
        returns (ResultSummary[] memory)
    {
        require(block.timestamp > endTime, "voting not ended");
        results = new ResultSummary[](_recipientId.length);
        for (uint256 i = 0; i < _recipientId.length; i++) {
            results[i].recipientId = _recipientId[i];
            results[i].votes = votesReceived[_recipientId[i]];
        }
        return results;
    }
}
