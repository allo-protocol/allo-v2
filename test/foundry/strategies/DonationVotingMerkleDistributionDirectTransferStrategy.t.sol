// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";

contract DonationVotingMerkleDistributionDirectTransferStrategyTest is
    DonationVotingMerkleDistributionBaseMockTest,
    PermitSignature
{
    DonationVotingMerkleDistributionDirectTransferStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(
            address(allo()),
            "DonationVotingMerkleDistributionBaseMock", permit2
        );
        return payable(address(_strategy));
    }

    function test_allocate() public override {
        uint256 balanceBefore = recipientAddress().balance;
        __register_accept_recipient_allocate();
        uint256 balanceAfter = recipientAddress().balance;

        assertEq(balanceAfter - balanceBefore, 1e18);
    }

    function test_allocate_ERC20() public {
        uint256 fromPrivateKey = 0x12341234;

        // 0xa229781d40864011729c753eac24a772890ff527
        address from = 0x9CfBAb222f01a2c3c334f7eb2FeDea266615421f;
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR());

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data = abi.encode(recipientId, permit2Data);

        uint256 balanceBefore = mockERC20.balanceOf(recipientAddress());

        vm.startPrank(from);
        mockERC20.approve(address(permit2), type(uint256).max);
        allo().allocate(poolId, data);
        vm.stopPrank();

        uint256 balanceAfter = mockERC20.balanceOf(recipientAddress());

        assertEq(balanceAfter - balanceBefore, 1e17);
    }
}
