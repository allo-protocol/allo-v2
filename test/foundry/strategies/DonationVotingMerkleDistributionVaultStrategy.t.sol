// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionVaultStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-vault/DonationVotingMerkleDistributionVaultStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

contract DonationVotingMerkleDistributionVaultStrategyTest is DonationVotingMerkleDistributionBaseMockTest {
    DonationVotingMerkleDistributionVaultStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionVaultStrategy(
            address(allo()),
            "DonationVotingMerkleDistributionBaseMock"
        );
        return payable(address(_strategy));
    }

    function test_claim() public {
        __register_accept_recipient_allocate();
        vm.warp(allocationEndTime + 1 days);

        DonationVotingMerkleDistributionVaultStrategy.Claim[] memory claim =
            new DonationVotingMerkleDistributionVaultStrategy.Claim[](1);
        claim[0] = DonationVotingMerkleDistributionVaultStrategy.Claim({recipientId: profile1_anchor(), token: NATIVE});

        vm.expectEmit(true, false, false, true);
        emit Claimed(profile1_anchor(), recipientAddress(), 1e18, NATIVE);

        _strategy.claim(claim);
    }

    function testRevert_claim_ALLOCATION_NOT_ENDED() public {
        __register_accept_recipient_allocate();

        DonationVotingMerkleDistributionVaultStrategy.Claim[] memory claim =
            new DonationVotingMerkleDistributionVaultStrategy.Claim[](1);
        claim[0] = DonationVotingMerkleDistributionVaultStrategy.Claim({recipientId: profile1_anchor(), token: NATIVE});

        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);

        _strategy.claim(claim);
    }

    function testRevert_claim_INVALID_amountIsZero() public {
        __register_accept_recipient_allocate();
        vm.warp(allocationEndTime + 1 days);

        DonationVotingMerkleDistributionVaultStrategy.Claim[] memory claim =
            new DonationVotingMerkleDistributionVaultStrategy.Claim[](1);
        claim[0] =
            DonationVotingMerkleDistributionVaultStrategy.Claim({recipientId: profile1_anchor(), token: address(123)});

        vm.expectRevert(INVALID.selector);

        _strategy.claim(claim);
    }

    function test_allocate() public override {
        address recipientId = __register_accept_recipient_allocate();
        assertEq(_strategy.claims(recipientId, NATIVE), 1e18);
    }
}
