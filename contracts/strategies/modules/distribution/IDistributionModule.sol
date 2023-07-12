// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IDistributionModule {
    function initializeDistributionModule(bytes memory _data) external;
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
