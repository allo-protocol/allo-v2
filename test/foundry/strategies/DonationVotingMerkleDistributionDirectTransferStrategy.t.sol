// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

contract DonationVotingMerkleDistributionDirectTransferStrategyTest is DonationVotingMerkleDistributionBaseMockTest {
    DonationVotingMerkleDistributionDirectTransferStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(
            address(allo()),
            "DonationVotingMerkleDistributionBaseMock"
        );
        return payable(address(_strategy));
    }

    function test_allocate() public override {
        uint256 balanceBefore = recipientAddress().balance;
        __register_accept_recipient_allocate();
        uint256 balanceAfter = recipientAddress().balance;

        assertEq(balanceAfter - balanceBefore, 1e18);
    }
}
