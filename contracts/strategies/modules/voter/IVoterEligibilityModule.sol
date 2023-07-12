// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IVoterEligibilityModule {
    function initializeVoterEligibilityModule(bytes _data) external;
    // used to initialize voter eligibility, for example with token address if token gated

    function isValidVoter(address _voter) public view returns (bool);
    // simply returns whether a voter is valid or not
    // this might need additional functions if, for example, it's based on allow list controlled by owner
}
