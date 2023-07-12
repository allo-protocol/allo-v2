// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IAllocationModule {
    function initializeAllocationModule(bytes memory _data) external;
    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[])
}
