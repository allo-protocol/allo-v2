// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
contract DonationVotingMerkleDistributionBaseMock is DonationVotingMerkleDistributionBaseStrategy {
    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name, ISignatureTransfer _permit2)
        DonationVotingMerkleDistributionBaseStrategy(_allo, _name, _permit2)
    {}

    function _tokenAmountInVault(address) internal pure override returns (uint256) {
        return 0;
    }
}
