// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
contract DonationVotingMerkleDistributionBaseMock is DonationVotingMerkleDistributionBaseStrategy {
    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) DonationVotingMerkleDistributionBaseStrategy(_allo, _name) {}

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _onAllocate(address _recipientId, uint256 _amount, address _token, address _sender) internal override {
        // do nothing
    }
}
