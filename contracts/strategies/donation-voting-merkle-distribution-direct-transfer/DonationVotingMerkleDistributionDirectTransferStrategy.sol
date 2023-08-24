// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
contract DonationVotingMerkleDistributionDirectTransferStrategy is DonationVotingMerkleDistributionBaseStrategy {
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

    // @notice Allocate tokens to the recipientAddress
    // @param _recipientId Id of the recipient
    // @param _amount Amount of tokens to allocate
    // @param _token Address of the token
    // @param _sender Address of the sender
    function _onAllocate(address _recipientId, uint256 _amount, address _token, address _sender) internal override {
        // Transfer the amount to recipient
        _transferAmountFrom(
            _token, TransferData({from: _sender, to: _recipients[_recipientId].recipientAddress, amount: _amount})
        );
    }
}
