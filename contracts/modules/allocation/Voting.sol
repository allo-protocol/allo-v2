// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*
This module allows eligible voters to cast a vote and subsequently calculates those votes for
a given strategy.

Examples:

    - Donation voting with offchain calculation
    - Simple voting with simple calculation
    - Credit voting (eligible voters receive X number of vote credits to distribute)
    - Governance token voting — the number of tokens you hold == the number of vote credits you can spend

*/

/// @title Voting
/// @notice Voting is a module that handles the casting and calculation of votes
/// @author allo-team
contract Voting {
    constructor() {}
}