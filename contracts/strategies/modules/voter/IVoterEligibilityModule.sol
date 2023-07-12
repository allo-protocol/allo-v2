// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IVoterEligibilityModule {
    function initializeVoterEligibilityModule(bytes _data) external;
    function isValidVoter(address _voter) public view returns (bool);
}
