// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IVotingModule is IStrategy {
    function initializeVotingModule(bytes _data) external;
    // initialize the voting itself, which could contain things like an ERC20 used to determine vote count

    function allocate(bytes memory _data, address _sender) external payable;
    // called via allo.sol by users to allocate votes to a recipient
    // this will update some data in this contract to store votes, etc.

    function getResults(address[] memory _recipientId, bytes memory _data) external view returns (ResultSummary[] memory);
    // returns the results for all the passed recipientIds
}
