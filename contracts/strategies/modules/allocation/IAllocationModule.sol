// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IAllocationModule {
    function initializeAllocationModule(bytes memory _data) external;
    // this will set any parameters needed for allocatio nmodules
    // i expect it to usually be unused

    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[])
    // this will call to getResults() in the voting module
    // it will use those results to determine the payouts
    // it can return all payouts, or just return for the recipients passed in, it's up to the strategy
}
