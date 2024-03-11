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
import {PermitSigUtilsDAI} from "../../utils/PermitSigUtilsDAI.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";
import {MockERC20Permit} from "../../utils/MockERC20Permit.sol";

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

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        uint256 amount = 1e17;
        uint256 deadline = block.timestamp + 1000;

        // We build a permit message using the erc2612 standard and we
        // use it to create the signature.
        // This message is not sent to the contract.
        PermitSigUtils.Permit memory permit1 = PermitSigUtils.Permit({
            owner: from,
            spender: address(_strategy),
            value: amount,
            nonce: nonce,
            deadline: deadline
        });

        PermitSigUtils permitSigUtils = new PermitSigUtils(vm, mockERC20Permit.DOMAIN_SEPARATOR());

        // signature of the permit "1" message
        bytes memory sig = permitSigUtils.sign(permit1, fromPrivateKey);

        // now we build a permit2 struct to be sent to the contract
        ISignatureTransfer.PermitTransferFrom memory permit2 = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(mockERC20Permit), amount: amount}),
            nonce: nonce,
            deadline: deadline
        });

        permit2.permitted.amount = permit1.value;

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit2, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit, permit2Data);

        uint256 balanceBefore = mockERC20Permit.balanceOf(recipientAddress());

        vm.startPrank(from);
        // we don't need to approve like with permit2
        allo().allocate(poolId, data);
        vm.stopPrank();

        uint256 balanceAfter = mockERC20Permit.balanceOf(recipientAddress());

        assertEq(balanceAfter, balanceBefore + 1e17);
    }

    function test_allocate_ERC20_Permit_DAI() public {
        uint256 fromPrivateKey = 0x12341234;
        address from = vm.addr(fromPrivateKey);

        mockERC20PermitDAI.mint(from, 1e18);

        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 nonce = 0;
        uint256 amount = 1e17;
        uint256 deadline = block.timestamp + 1000;

        // We build a permit message using the erc2612 standard and we
        // use it to create the signature.
        // This message is not sent to the contract.
        PermitSigUtilsDAI.Permit memory permit1 = PermitSigUtilsDAI.Permit({
            holder: from,
            spender: address(_strategy),
            nonce: nonce,
            expiry: deadline,
            allowed: true
        });

        PermitSigUtilsDAI permitSigUtilsDAI = new PermitSigUtilsDAI(vm, mockERC20PermitDAI.DOMAIN_SEPARATOR());

        // signature of the permit "1" message
        bytes memory sig = permitSigUtilsDAI.sign(permit1, fromPrivateKey);

        // now we build a permit2 struct to be sent to the contract
        ISignatureTransfer.PermitTransferFrom memory permit2 = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(mockERC20PermitDAI), amount: amount}),
            nonce: nonce,
            deadline: deadline
        });

        // Not needed for DAI. The DAI implementation has an allowed field that sets the allowance to 0 or max.
        // permit2.permitted.amount = permit1.value;

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit2, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.PermitDAI, permit2Data);

        uint256 balanceBefore = mockERC20PermitDAI.balanceOf(recipientAddress());

        vm.startPrank(from);
        // we don't need to approve like with permit2
        allo().allocate(poolId, data);
        vm.stopPrank();

        uint256 balanceAfter = mockERC20PermitDAI.balanceOf(recipientAddress());

        assertEq(balanceAfter, balanceBefore + 1e17);
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
