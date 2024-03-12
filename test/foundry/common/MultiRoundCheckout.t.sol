// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
import {MultiRoundCheckout} from "../../../contracts/core/libraries/MultiRoundCheckout.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {TestStrategy} from "../../utils/TestStrategy.sol";
import {MockStrategy} from "../../utils/MockStrategy.sol";
import {MockERC20} from "../../utils/MockERC20.sol";
import {GasHelpers} from "../../utils/GasHelpers.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

contract MultiRoundCheckoutTest is Test, AlloSetup, RegistrySetupFull, Native, Errors, GasHelpers {
    struct Permit2Data {
        ISignatureTransfer.PermitTransferFrom permit;
        bytes signature;
    }

    enum PermitType {
        None,
        Permit,
        PermitDAI,
        Permit2
    }

    MockStrategy public strategy;
    MockERC20 public token;
    MultiRoundCheckout public multiRoundCheckout;

    uint256 mintAmount = 1000000 * 10 ** 18;
    uint256 public nonce;
    string public name;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        token = new MockERC20();
        multiRoundCheckout = new MultiRoundCheckout();
        multiRoundCheckout.initialize();

        token.mint(local(), mintAmount);
        token.mint(allo_owner(), mintAmount);
        token.mint(pool_admin(), mintAmount);
        token.approve(address(allo()), mintAmount);

        vm.prank(pool_admin());
        token.approve(address(allo()), mintAmount);

        strategy = new MockStrategy(address(allo()));

        vm.startPrank(allo_owner());
        allo().transferOwnership(local());
        vm.stopPrank();
    }

    function test_initialize() public {}

    function testRevert_initialize() public {
        vm.expectRevert();
        multiRoundCheckout.initialize();
    }

    function test_vote() public {
        // bytes[][] memory votes;
        // address[] memory rounds;
        // uint256[] memory amounts;

        // votes = new bytes[][](1);
        // rounds = new address[](1);
        // amounts = new uint256[](1);

        // votes[0] = new bytes[](1);
        // rounds[0] = makeAddr("round");
        // amounts[0] = 1e18;

        // votes[0][0] = abi.encodePacked("test");

        // multiRoundCheckout.vote(votes, rounds, amounts);

        // assertEq(token.balanceOf(address(multiRoundCheckout)), 0);
    }

    function testRevert_vote_MISMATCH() public {
        bytes[][] memory votes;
        address[] memory rounds;
        uint256[] memory amounts;

        votes = new bytes[][](2);
        rounds = new address[](1);
        amounts = new uint256[](1);

        votes[0] = new bytes[](1);
        rounds[0] = makeAddr("round");
        amounts[0] = 1e18;

        votes[0][0] = abi.encodePacked("test");

        // Test mismatch of ecnoded data
        vm.expectRevert(MISMATCH.selector);
        multiRoundCheckout.vote(votes, rounds, amounts);

        votes = new bytes[][](1);
        rounds = new address[](1);
        amounts = new uint256[](2);

        votes[0] = new bytes[](1);
        rounds[0] = makeAddr("round");
        amounts[0] = 1e18;

        vm.expectRevert(MISMATCH.selector);
        multiRoundCheckout.vote(votes, rounds, amounts);

        assertEq(token.balanceOf(address(multiRoundCheckout)), 0);
    }

    function test_voteDAIPermit() public {
        // uint256 totalAmount = 1000;
        // uint256 deadline = 1000;
        // uint8 v = 27;
        // bytes32 r = 0x0;
        // bytes32 s = 0x0;

        // bytes[][] memory votes;
        // address[] memory rounds;
        // uint256[] memory amounts;

        // multiRoundCheckout.voteDAIPermit(
        //     votes,
        //     rounds,
        //     amounts,
        //     totalAmount,
        //     address(token),
        //     deadline,
        //     nonce,
        //     v,
        //     r,
        //     s
        // );
    }

    function testRevert_voteDAIPermit() public {
        // uint256 totalAmount = 1000;
        // uint256 deadline = 1000;
        // uint8 v = 27;
        // bytes32 r = 0x0;
        // bytes32 s = 0x0;

        // bytes[][] memory votes;
        // address[] memory rounds;
        // uint256[] memory amounts;

        // multiRoundCheckout.voteDAIPermit(
        //     votes,
        //     rounds,
        //     amounts,
        //     totalAmount,
        //     address(token),
        //     deadline,
        //     nonce,
        //     v,
        //     r,
        //     s
        // );
    }

    function test_donateV2() public {
        address[] memory rounds;
        PermitType[] memory permitType;
        Permit2Data[] memory p2Data;

        rounds = new address[](1);
        permitType = new PermitType[](1);
        p2Data = new Permit2Data[](1);

        rounds[0] = makeAddr("round");
        permitType[0] = PermitType.Permit2;
        p2Data[0] = Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: 1e18}),
                nonce: 0,
                deadline: 0
            }),
            signature: abi.encodePacked("test")
        });

        multiRoundCheckout.donateV2(abi.encode(rounds, permitType, p2Data));
    }

    function testRevert_donateV2_MISMATCH() public {
        address[] memory rounds;
        PermitType[] memory permitType;
        Permit2Data[] memory p2Data;

        rounds = new address[](1);
        permitType = new PermitType[](2);
        p2Data = new Permit2Data[](1);

        rounds[0] = makeAddr("round");
        permitType[0] = PermitType.Permit2;
        p2Data[0] = Permit2Data({
            permit: ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: 1e18}),
                nonce: 0,
                deadline: 0
            }),
            signature: abi.encodePacked("test")
        });

        vm.expectRevert(MISMATCH.selector);
        multiRoundCheckout.donateV2(abi.encode(rounds, permitType, p2Data));
    }
}
