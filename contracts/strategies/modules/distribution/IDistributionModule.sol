// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { IStrategy }  from "../../IStrategy.sol";

interface IDistributionModule {
    function initializeDistributionModule(bytes memory _data) external;
    // this will set parameters for distribution, such as a merkle root

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
    // this will distribute tokens to recipients
    // it will call to getPayouts() from the allocation module to determine what to pay
    // the allocation module will return TOTAL amount to be paid to each recipient
    // this contract will need to track the amount paid already, so that it doesn't double pay
}
