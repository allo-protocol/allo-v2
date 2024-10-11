// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "strategies/libraries/QVHelper.sol";

/// @title Mock QV Helper
/// @notice A mock contract for testing Quadratic Voting Library
contract MockQVHelper {
    using QVHelper for QVHelper.VotingState;

    QVHelper.VotingState internal _votingState;

    function vote(address[] memory _recipients, uint256[] memory _votes) public {
        _votingState.vote(_recipients, _votes);
    }

    function voteWithCredits(address[] memory _recipients, uint256[] memory _voiceCredits) public {
        _votingState.voteWithVoiceCredits(_recipients, _voiceCredits);
    }

    function getPayoutAmount(address[] memory _recipients, uint256 _poolAmount)
        public
        view
        returns (uint256[] memory _payouts)
    {
        return _votingState.getPayout(_recipients, _poolAmount);
    }

    function getVotes(address _recipient) public view returns (uint256 _recipientVotes) {
        return _votingState.recipientVotes[_recipient];
    }

    function getVoiceCredits(address _recipient) public view returns (uint256 _recipientVoiceCredits) {
        return _votingState.recipientVoiceCredits[_recipient];
    }

    function getTotalVotes() public view returns (uint256 _totalVotes) {
        return _votingState.totalVotes;
    }

    function getTotalVoiceCredits() public view returns (uint256 _totalVoiceCredits) {
        return _votingState.totalVoiceCredits;
    }
}
