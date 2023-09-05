// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionVaultStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-vault/DonationVotingMerkleDistributionVaultStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";

contract DonationVotingMerkleDistributionVaultStrategyTest is
    DonationVotingMerkleDistributionBaseMockTest,
    PermitSignature
{
    DonationVotingMerkleDistributionVaultStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionVaultStrategy(
            address(allo()),
            "DonationVotingMerkleDistributionBaseMock", permit2
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

    function test_allocate_ERC20() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 fromPrivateKey = 0x12341234;
        // 0xa229781d40864011729c753eac24a772890ff527
        address from = 0x9CfBAb222f01a2c3c334f7eb2FeDea266615421f;
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR());

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data = abi.encode(recipientId, permit2Data);

        vm.startPrank(from);
        mockERC20.approve(address(permit2), type(uint256).max);
        allo().allocate(poolId, data);
        vm.stopPrank();

        assertEq(_strategy.claims(recipientId, address(mockERC20)), 1e17);
    }
}
