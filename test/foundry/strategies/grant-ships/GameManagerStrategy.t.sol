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

    function test_RegisterRecipient() public {
        (address recipientId, bytes memory data) = _register_recipient_return_data();

        GameManagerStrategy.Applicant memory applicant = gameManager().getApplicant(recipientId);
        // Check that the recipient was registered
        assertEq(applicant.applicantId, profile1_anchor());
        assertEq(applicant.metadata.pointer, "Ship 1");
        assertEq(applicant.metadata.protocol, 1);

        // Check data returned from helper function
        assertEq(uint8(applicant.status), uint8(IStrategy.Status.Pending));
        assertEq(data, abi.encode(recipientId, "Ship Name", Metadata(1, "Ship 1")));
    }

    // ====================================
    // =========== Helpers ================
    // ====================================

    function _register_recipient_return_data() internal returns (address recipientId, bytes memory data) {
        recipientId = profile1_anchor();

        Metadata memory metadata = Metadata(1, "Ship 1");

        data = abi.encode(recipientId, "Ship Name", metadata);

        vm.expectEmit(true, true, true, true);
        emit Registered(recipientId, data, profile1_member1());
        gameManager().getPoolId();

        vm.startPrank(profile1_member1());
        allo().registerRecipient(gameManager().getPoolId(), data);
        vm.stopPrank();
    }
}
