// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IVotingModule is IStrategy {
    function initializeVotingModule(bytes _data) external;

    function allocate(bytes memory _data, address _sender) external payable;

    function getResults(
        address[] memory _recipientId,
        bytes memory _data
    ) external view returns (ResultSummary[] memory);
}
