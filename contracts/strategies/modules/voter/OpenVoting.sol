// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IVoterEligibilityModule }  from "./IVoterEligibilityModule.sol";

contract OpenVoting is IVoterEligibilityModule {
    function initializeVoterEligibilityModule(bytes _data) external {}

    function isValidVoter(address _voter) public view returns (bool) {
        return true;
    }
}
