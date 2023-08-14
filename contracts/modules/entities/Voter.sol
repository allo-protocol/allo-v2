// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*
This is the module by which a voter is determined to be eligible to cast a vote.

Example:
    - Allowlist / blocklist — a specific list of addresses is allowed or not allowed
    - Address holds some verifier 
    - Passport stamp
    - NFT
    - Address has interacted with some contract

*/

/// @title Voter
/// @notice Voter is a module that handles the eligibility of a voter to cast a vote
/// @author allo-team
contract Voter {
    struct VoterObject {
        address voter;
        uint256 voteCredits;
        uint256 voteCreditsUsed;
        uint256 voteCreditsRemaining;
        uint256 voteCreditsUsedPercentage;
        uint256 voteCreditsRemainingPercentage;
    }

    // @notice allowed voters
    mapping(address => bool) public allowedVoters;

    // @notice disallowed voters
    mapping(address => bool) public disallowedVoters;

    constructor() {}

    /// @notice Adds a voter to the allowed list
    /// @param _voter The address of the voter to add
    function _addAllowedVoter(address _voter) internal {
        allowedVoters[_voter] = true;
    }

    /// @notice Removes a voter from the allowed list
    /// @param _voter The address of the voter to remove
    function _removeAllowedVoter(address _voter) internal {
        allowedVoters[_voter] = false;
    }

    /// @notice Adds a voter to the disallowed list
    /// @param _voter The address of the voter to add
    function _addDisallowedVoter(address _voter) internal {
        disallowedVoters[_voter] = true;
    }

    /// @notice Removes a voter from the disallowed list
    /// @param _voter The address of the voter to remove
    function _removeDisallowedVoter(address _voter) internal {
        disallowedVoters[_voter] = false;
    }
}
