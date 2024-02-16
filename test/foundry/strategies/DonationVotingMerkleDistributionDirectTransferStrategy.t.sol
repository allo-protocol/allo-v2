// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
import {PermitSigUtils} from "../../utils/PermitSigUtils.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";

contract DonationVotingMerkleDistributionDirectTransferStrategyTest is DonationVotingMerkleDistributionBaseMockTest {
    DonationVotingMerkleDistributionDirectTransferStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(
            address(allo()), "DonationVotingMerkleDistributionBaseMock", permit2
        );
        return payable(address(_strategy));
    }

    function test_allocate() public override {
        uint256 balanceBefore = recipientAddress().balance;
        __register_accept_recipient_allocate();
        uint256 balanceAfter = recipientAddress().balance;

        assertEq(balanceAfter - balanceBefore, 1e18);
    }

    function test_allocate_ERC20_Permit2() public {
        uint256 fromPrivateKey = 0x12341234;

        address from = vm.addr(fromPrivateKey);
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig =
            __getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR(), address(_strategy));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        uint256 balanceBefore = mockERC20.balanceOf(recipientAddress());

        vm.startPrank(from);
        mockERC20.approve(address(permit2), type(uint256).max);
        allo().allocate(poolId, data);
        vm.stopPrank();

        uint256 balanceAfter = mockERC20.balanceOf(recipientAddress());

        assertEq(balanceAfter - balanceBefore, 1e17);
    }

    function test_allocate_ERC20_Permit() public {
        uint256 fromPrivateKey = 0x12341234;
        address from = vm.addr(fromPrivateKey);

        mockERC20Permit.mint(from, 1e18);
        mockERC20Permit.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        // uint256 nonce = 0;
        // ISignatureTransfer.PermitTransferFrom
        //     memory permit = defaultERC20PermitTransfer(
        //         address(mockERC20Permit),
        //         nonce
        //     );
        // permit.permitted.amount = 1e17;
        // bytes memory sig = __getPermitTransferSignature(
        //     permit,
        //     fromPrivateKey,
        //     permit2.DOMAIN_SEPARATOR(),
        //     address(_strategy)
        // );

        // DonationVotingMerkleDistributionBaseStrategy.Permit2Data
        //     memory permit2Data = DonationVotingMerkleDistributionBaseStrategy
        //         .Permit2Data({permit: permit, signature: sig});

        DonationVotingMerkleDistributionBaseStrategy.Permit memory permit = DonationVotingMerkleDistributionBaseStrategy
            .Permit({owner: from, spender: address(_strategy), value: 1e17, nonce: 0, deadline: type(uint256).max});

        PermitSigUtils permitSigUtils = new PermitSigUtils(mockERC20Permit.DOMAIN_SEPARATOR());
        bytes32 digest = permitSigUtils.getTypedDataHash(permit);
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = vm.sign(fromPrivateKey, digest);

        DonationVotingMerkleDistributionBaseStrategy.PermitData memory permitData =
            DonationVotingMerkleDistributionBaseStrategy.PermitData({permit: permit, v: v, r: r, s: s});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit, permitData);

        uint256 balanceBefore = mockERC20Permit.balanceOf(recipientAddress());

        // vm.startPrank(from);
        // // we don't need to approve like with permit2
        // allo().allocate(poolId, data);
        // vm.stopPrank();

        // uint256 balanceAfter = mockERC20Permit.balanceOf(recipientAddress());

        // assertEq(balanceAfter, balanceBefore + 1e17);
    }

    function testRevert_allocate_ERC20_InvalidSigner() public {
        uint256 fromPrivateKey = 0x12341234;

        address from = randomAddress(); // invalid signer
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig =
            __getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR(), address(strategy));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        vm.startPrank(from);

        mockERC20.approve(address(permit2), type(uint256).max);

        vm.expectRevert(InvalidSigner.selector);
        allo().allocate(poolId, data);

        vm.stopPrank();
    }

    function testRevert_allocate_ERC20_SignatureExpired() public {
        uint256 fromPrivateKey = 0x12341234;

        address from = vm.addr(fromPrivateKey);
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        permit.deadline = 0; // expired

        bytes memory sig =
            __getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR(), address(strategy));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        vm.startPrank(from);

        mockERC20.approve(address(permit2), type(uint256).max);

        vm.expectRevert(abi.encodePacked(SignatureExpired.selector, uint256(0)));
        allo().allocate(poolId, data);

        vm.stopPrank();
    }

    function testRevert_allocate_ERC20_InvalidSignature() public {
        uint256 fromPrivateKey = 0x12341234;

        address from = vm.addr(fromPrivateKey);
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;

        bytes memory sig = "0x_Inavlid_Signature_Inavlid_Signature_Inavlid_Signature_Inavlid";

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        vm.startPrank(from);

        mockERC20.approve(address(permit2), type(uint256).max);

        vm.expectRevert(InvalidSignature.selector);
        allo().allocate(poolId, data);

        vm.stopPrank();
    }
}
