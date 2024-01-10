// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {AlloSetup} from "../../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../../shared/RegistrySetup.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {EventSetup} from "../../shared/EventSetup.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";
import {GameManagerSetup} from "./GameManagerSetup.t.sol";
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";

contract GameManagerStrategyTest is Test, GameManagerSetup, Errors, EventSetup {
    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});

        __ManagerSetup();
    }

    function test_registerRecipient() public {
        (address recipientId, bytes memory data) = _register_recipient_return_data();

        GameManagerStrategy.Applicant memory applicant = gameManager().getApplicant(recipientId);
        // Check that the recipient was registered
        assertEq(applicant.applicantId, profile1_anchor());
        assertEq(applicant.metadata.pointer, "Ship 1");
        assertEq(applicant.metadata.protocol, 1);
        assertEq(applicant.shipName, "Ship Name");

        // Check data returned from helper function
        assertEq(uint8(applicant.status), uint8(IStrategy.Status.Pending));
        assertEq(data, abi.encode(recipientId, "Ship Name", Metadata(1, "Ship 1")));
    }

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        address recipientId = profile1_anchor();

        Metadata memory metadata = Metadata(1, "Ship 1");

        bytes memory data = abi.encode(recipientId, "Ship Name", metadata);

        uint256 poolId = gameManager().getPoolId();
        address rando = randomAddress();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.startPrank(rando);
        allo().registerRecipient(poolId, data);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_INVALID_METADATA() public {
        address recipientId = profile1_anchor();

        Metadata memory badMetadata = Metadata(1, "");

        bytes memory data = abi.encode(recipientId, "Ship Name", badMetadata);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(INVALID_METADATA.selector);
        vm.startPrank(profile1_member1());
        allo().registerRecipient(poolId, data);
        vm.stopPrank();
    }

    function testRevert_registerRecipient_UpdateProfile() public {
        (address applicantId,) = _register_recipient_return_data();

        Metadata memory metadata = Metadata(1, "Ship 1: Part 2");

        bytes memory data = abi.encode(applicantId, "Ship Name: Part 2", metadata);

        uint256 poolId = gameManager().getPoolId();

        vm.startPrank(profile1_member1());
        allo().registerRecipient(poolId, data);
        vm.stopPrank();

        GameManagerStrategy.Applicant memory newApplicant = gameManager().getApplicant(applicantId);

        assertEq(newApplicant.metadata.pointer, "Ship 1: Part 2");
        assertEq(newApplicant.metadata.protocol, 1);
        assertEq(uint8(newApplicant.status), uint8(IStrategy.Status.Pending));
        assertEq(newApplicant.shipName, "Ship Name: Part 2");
    }

    // ====================================
    // =========== Helpers ================
    // ====================================

    function _register_recipient_return_data() internal returns (address applicantId, bytes memory data) {
        applicantId = profile1_anchor();

        Metadata memory metadata = Metadata(1, "Ship 1");

        data = abi.encode(applicantId, "Ship Name", metadata);

        vm.expectEmit(true, true, true, true);
        emit Registered(applicantId, data, profile1_member1());
        gameManager().getPoolId();

        vm.startPrank(profile1_member1());
        allo().registerRecipient(gameManager().getPoolId(), data);
        vm.stopPrank();
    }
}
