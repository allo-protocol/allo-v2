// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Test contracts
import "forge-std/Test.sol";

import {DonationVotingMerkleDistributionBaseMockTest} from "./DonationVotingMerkleDistributionBase.t.sol";
import {DonationVotingMerkleDistributionVaultStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-vault/DonationVotingMerkleDistributionVaultStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

contract DonationVotingMerkleDistributionVaultStrategyTest is DonationVotingMerkleDistributionBaseMockTest {
    DonationVotingMerkleDistributionVaultStrategy _strategy;

    function _deployStrategy() internal override returns (address payable) {
        _strategy = new DonationVotingMerkleDistributionVaultStrategy(
            address(allo()), "DonationVotingMerkleDistributionBaseMock", permit2
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

        address from = vm.addr(fromPrivateKey);
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig =
            __getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR(), address(_strategy));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        vm.startPrank(from);
        mockERC20.approve(address(permit2), type(uint256).max);
        allo().allocate(poolId, data);
        vm.stopPrank();

        assertEq(_strategy.claims(recipientId, address(mockERC20)), 1e17);
    }

    function test_withdraw_ERC20() public {
        address recipientId = __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        uint256 fromPrivateKey = 0x12341234;

        address from = vm.addr(fromPrivateKey);
        mockERC20.mint(from, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig =
            __getPermitTransferSignature(permit, fromPrivateKey, permit2.DOMAIN_SEPARATOR(), address(_strategy));

        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
            DonationVotingMerkleDistributionBaseStrategy.Permit2Data({permit: permit, signature: sig});

        bytes memory data =
            abi.encode(recipientId, DonationVotingMerkleDistributionBaseStrategy.PermitType.Permit2, permit2Data);

        vm.startPrank(from);
        mockERC20.approve(address(permit2), type(uint256).max);
        allo().allocate(poolId, data);
        vm.stopPrank();

        mockERC20.transfer(address(_strategy), 1e17);
        assertEq(mockERC20.balanceOf(address(_strategy)), 2e17);

        uint256 balanceBefore = mockERC20.balanceOf(pool_admin());

        vm.warp(allocationEndTime + 31 days);
        vm.startPrank(pool_admin());
        _strategy.withdraw(address(mockERC20));

        assertEq(mockERC20.balanceOf(pool_admin()), balanceBefore + 1e17);
        assertEq(mockERC20.balanceOf(address(_strategy)), 1e17);
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

    function testRevert_allocate_ERC20_InvalidSigner_frontrun() public {
        // register recipient
        __register_accept_recipient();
        vm.warp(allocationStartTime + 1);

        // create signer
        (address signer, uint256 signerKrey) = makeAddrAndKey("signer");

        vm.startPrank(signer);
        // mint erc20 token
        mockERC20.mint(signer, 1e18);
        mockERC20.approve(address(permit2), type(uint256).max);

        // create permit 2
        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permit = defaultERC20PermitTransfer(address(mockERC20), nonce);
        permit.permitted.amount = 1e17;
        bytes memory sig =
            __getPermitTransferSignature(permit, signerKrey, permit2.DOMAIN_SEPARATOR(), address(strategy));

        // try front run attack
        vm.startPrank(makeAddr("front-runner"));

        vm.expectRevert(InvalidSigner.selector);
        permit2.permitTransferFrom(
            permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(strategy), requestedAmount: 1e17}),
            signer,
            sig
        );
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
