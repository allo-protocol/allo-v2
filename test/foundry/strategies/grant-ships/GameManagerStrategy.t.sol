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
import {GrantShipStrategy} from "./GrantShipStrategy.t.sol";

import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";

contract GameManagerStrategyTest is Test, GameManagerSetup, Errors, EventSetup {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    event RoundCreated(uint256 gameIndex, address token, uint256 totalRoundAmount);
    event ApplicationRejected(address recipientAddress);
    event ShipLaunched(
        address shipAddress, uint256 shipPoolId, address applicantId, string shipName, Metadata metadata
    );

    /// ===============================
    /// ========== State ==============
    /// ===============================

    uint256 internal constant _gameAmount = 90_000e18;
    uint256 internal constant _shipAmount = 30_000e18;

    GrantShipStrategy internal ship;

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});

        __ManagerSetup();
    }

    function test_registerRecipient() public {
        address recipientId = _register_recipient();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientId);
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        // Check that the recipient was registered
        assertEq(recipient.recipientAddress, profile1_anchor());
        assertEq(recipient.profileId, profileId);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(0));
        assertEq(recipient.previousAddress, address(0));
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(IStrategy.Status.Pending));
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

    function test_registerRecipient_UpdateApplication() public {
        address recipientId = _register_recipient();

        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;
        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientId);

        assertEq(recipient.recipientAddress, profile1_anchor());
        assertEq(recipient.profileId, profileId);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(0));
        assertEq(recipient.previousAddress, address(0));
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(IStrategy.Status.Pending));

        Metadata memory metadata = Metadata(1, "Ship 1: Part 2");

        bytes memory data = abi.encode(recipientId, "Ship Name: Part 2", metadata);

        uint256 poolId = gameManager().getPoolId();

        vm.startPrank(profile1_member1());
        allo().registerRecipient(poolId, data);
        vm.stopPrank();

        GameManagerStrategy.Recipient memory newRecipient = gameManager().getRecipient(recipientId);

        assertEq(newRecipient.recipientAddress, profile1_anchor());
        assertEq(newRecipient.profileId, profileId);
        assertEq(newRecipient.shipName, "Ship Name: Part 2");
        assertEq(newRecipient.shipAddress, address(0));
        assertEq(newRecipient.previousAddress, address(0));
        assertEq(newRecipient.shipPoolId, 0);
        assertEq(newRecipient.grantAmount, 0);
        assertEq(newRecipient.metadata.pointer, "Ship 1: Part 2");
        assertEq(newRecipient.metadata.protocol, 1);
        assertEq(uint8(newRecipient.status), uint8(IStrategy.Status.Pending));
    }

    function test_createRound() public {
        _register_create_round();

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);

        assertEq(_gameAmount, round.totalRoundAmount);
        assertEq(address(ARB()), round.token);
        assertEq(uint8(round.roundStatus), uint8(GameManagerStrategy.RoundStatus.Pending));
        assertEq(uint8(round.startTime), 0);
        assertEq(uint8(round.endTime), 0);
        assertEq(round.ships.length, 0);
    }

    function testRevert_createRound_UNAUTHORIZED() public {
        _register_create_round();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.startPrank(randomAddress());
        gameManager().createRound(_gameAmount, address(ARB()));
        vm.stopPrank();
    }

    function testRevert_createRound_INVALID_STATUS() public {
        _register_create_round();

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().createRound(_gameAmount, address(ARB()));
        vm.stopPrank();
    }

    function test_reviewApplicant_approve() public {
        address recipientAddress = register_create_approve();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientAddress);

        assertEq(recipient.recipientAddress, recipientAddress);
        assertEq(recipient.profileId, registry().getProfileByAnchor(profile1_anchor()).id);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(ship));
        assertEq(recipient.previousAddress, address(0));
        assertEq(recipient.shipPoolId, ship.getPoolId());
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(GameManagerStrategy.ShipStatus.Accepted));
    }

    function testRevert_reviewApplicant_INVALID_STATUS() public {
        address applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.ShipStatus.None,
            ShipInitData(true, true, true, "Ship Name", Metadata(1, "Ship 1"), team(0).wearer, shipOperator(0).id)
        );
        vm.stopPrank();
    }

    function test_reviewApplicant_reject() public {
        address recipientAddress = register_create_reject();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientAddress);

        assertEq(recipient.recipientAddress, recipientAddress);
        assertEq(recipient.profileId, registry().getProfileByAnchor(profile1_anchor()).id);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(0));
        assertEq(recipient.previousAddress, address(0));
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(GameManagerStrategy.ShipStatus.Rejected));
    }

    // ====================================
    // =========== Helpers ================
    // ====================================

    function register_create_reject() internal returns (address applicantId) {
        applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit ApplicationRejected(applicantId);

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.ShipStatus.Rejected,
            ShipInitData(true, true, true, "Ship Name", Metadata(1, "Ship 1"), team(0).wearer, shipOperator(0).id)
        );
        vm.stopPrank();
    }

    function register_create_approve() internal returns (address applicantId) {
        applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        address payable shipAddress = gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.ShipStatus.Accepted,
            ShipInitData(true, true, true, "Ship Name", Metadata(1, "Ship 1"), team(0).wearer, shipOperator(0).id)
        );
        vm.stopPrank();

        ship = GrantShipStrategy(shipAddress);
    }

    function _register_create_round() internal returns (address recipientId) {
        recipientId = _register_recipient();

        address arbAddress = address(ARB());

        vm.startPrank(facilitator().wearer);

        vm.expectEmit(true, true, true, true);
        emit RoundCreated(0, arbAddress, _gameAmount);

        gameManager().createRound(_gameAmount, arbAddress);
        vm.stopPrank();
    }

    function _register_recipient_return_data() internal returns (address recipientId, bytes memory data) {
        recipientId = profile1_anchor();

        Metadata memory metadata = Metadata(1, "Ship 1");

        data = abi.encode(recipientId, "Ship Name", metadata);

        vm.expectEmit(true, true, true, true);
        emit Registered(recipientId, data, profile1_member1());

        vm.startPrank(profile1_member1());
        allo().registerRecipient(gameManager().getPoolId(), data);
        vm.stopPrank();
    }

    function _register_recipient() internal returns (address recipientId) {
        (recipientId,) = _register_recipient_return_data();
    }
}
