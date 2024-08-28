// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// External Libraries
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// Test libraries
import {MockGatingExtension} from "../../../mocks/MockGatingExtension.sol";
import {BaseGatingExtension} from "./BaseGatingExtension.sol";
import {NFTGatingExtension} from "strategies/extensions/gating/NFTGatingExtension.sol";

contract NFTGatingExtensionTest is BaseGatingExtension {
    function test_onlyWithNFT() public {
        vm.mockCall(nft, abi.encodeWithSelector(IERC721(nft).balanceOf.selector, actor), abi.encode(1));
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(nft);
    }

    function testRevert_onlyWithNFT_nftZeroAddress() public {
        address _nft = address(0);
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INVALID_TOKEN.selector);
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(_nft);
    }

    function testRevert_onlyWithNFT_actorZeroAddress() public {
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INVALID_ACTOR.selector);
        vm.prank(address(0));
        gatingExtension.onlyWithNFTHelper(nft);
    }

    function testRevert_onlyWithNFT_actorNotOwner() public {
        vm.mockCall(nft, abi.encodeWithSelector(IERC721(nft).balanceOf.selector, actor), abi.encode(0));
        vm.expectRevert(NFTGatingExtension.NFTGatingExtension_INSUFFICIENT_BALANCE.selector);
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(nft);
    }
}
