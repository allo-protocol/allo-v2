// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockNFTGatingExtension} from "test/smock/MockMockNFTGatingExtension.sol";
import {NFTGatingExtension} from "contracts/strategies/extensions/gating/NFTGatingExtension.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTGatingExtensionUnit is Test {
    MockMockNFTGatingExtension nftGatingExtension;

    function setUp() public {
        nftGatingExtension = new MockMockNFTGatingExtension(address(0));
    }

    function test_RevertWhen_NftAddressIsZero(address _actor) external {
        // It should revert
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INVALID_TOKEN.selector);

        nftGatingExtension.call__checkOnlyWithNFT(address(0), _actor);
    }

    function test_RevertWhen_ActorAddressIsZero(address _nft) external {
        vm.assume(_nft != address(0));

        // It should revert
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INVALID_ACTOR.selector);

        nftGatingExtension.call__checkOnlyWithNFT(_nft, address(0));
    }

    function test_RevertWhen_ActorBalanceIsEqualZero(address _nft, address _actor) external {
        vm.assume(_nft != address(0));
        vm.assume(_actor != address(0));

        vm.mockCall(address(_nft), abi.encodeWithSelector(IERC721.balanceOf.selector, _actor), abi.encode(uint256(0)));

        // It should revert
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INSUFFICIENT_BALANCE.selector);

        nftGatingExtension.call__checkOnlyWithNFT(_nft, _actor);
    }

    function test_WhenParametersAreValid(address _nft, address _actor) external {
        vm.assume(_nft != address(0));
        vm.assume(_actor != address(0));

        vm.mockCall(address(_nft), abi.encodeWithSelector(IERC721.balanceOf.selector, _actor), abi.encode(uint256(1)));

        // It should execute successfully
        nftGatingExtension.call__checkOnlyWithNFT(_nft, _actor);
    }
}
