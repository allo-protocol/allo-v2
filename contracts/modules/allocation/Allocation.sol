// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*
This module provides the fund allocation for a given strategy pool of funds.

Examples:

    - Proportional distribution (the calculated proportion of votes = the proportion of the pool each recipient gets)
    - Winner take all
    - Ranked places (i.e. only top X projects receive discrete funding amounts)
    - Discrete sum — as long as project receives at or above a given threshold for proportion of votes than they receive a specific amount of funds

*/

/// @title Allocation
/// @notice Allocation is a module that handles the distribution of funds to recipients based on the results of a vote/allocation
/// @author allo-team
contract Allocation {
    constructor() {}
}
