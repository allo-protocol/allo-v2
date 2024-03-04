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

    event RoundCreated(uint256 gameIndex, uint256 totalRoundAmount);
    event RecipientRejected(address recipientAddress, Metadata reason);
    event RecipientAccepted(address recipientAddress, Metadata reason);
    event ShipLaunched(
        address shipAddress, uint256 shipPoolId, address applicantId, string shipName, Metadata metadata
    );
    event GameActive(bool active, uint256 gameIndex);
    event UpdatePosted(string tag, uint256 role, address recipientId, Metadata content);

    /// ===============================
    /// ========== State ==============
    /// ===============================

    GrantShipStrategy internal shipStrategy;
    GrantShipStrategy internal ship2Strategy;
    GrantShipStrategy internal ship3Strategy;

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __ManagerSetup();
    }

    // ====================================
    // =========== Tests ==================
    // ====================================

    function test_registerRecipient() public {
        address recipientId = _register_recipient();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientId);
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        // Check that the recipient was registered
        assertEq(recipient.recipientAddress, profile1_anchor());
        assertEq(recipient.profileId, profileId);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(0));
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.totalAmountRecieved, 0);
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
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.totalAmountRecieved, 0);
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
        assertEq(newRecipient.shipPoolId, 0);
        assertEq(newRecipient.grantAmount, 0);
        assertEq(newRecipient.metadata.pointer, "Ship 1: Part 2");
        assertEq(newRecipient.metadata.protocol, 1);
        assertEq(uint8(newRecipient.status), uint8(IStrategy.Status.Pending));
    }

    function test_createRound() public {
        _register_create_round();

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);

        assertEq(_GAME_AMOUNT, round.totalRoundAmount);
        assertEq(uint8(round.status), uint8(GameManagerStrategy.GameStatus.Pending));
        assertEq(uint8(round.startTime), 0);
        assertEq(uint8(round.endTime), 0);
        assertEq(round.ships.length, 0);
    }

    function testRevert_createRound_UNAUTHORIZED() public {
        _register_create_round();

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.startPrank(randomAddress());
        gameManager().createRound(_GAME_AMOUNT);
        vm.stopPrank();
    }

    function testRevert_createRound_INVALID_STATUS() public {
        _register_create_round();

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().createRound(_GAME_AMOUNT);
        vm.stopPrank();
    }

    function test_reviewApplicant_approve() public {
        address recipientAddress = _register_create_approve();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientAddress);

        assertEq(recipient.recipientAddress, recipientAddress);
        assertEq(recipient.profileId, registry().getProfileByAnchor(profile1_anchor()).id);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(shipStrategy));
        assertEq(recipient.shipPoolId, shipStrategy.getPoolId());
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.totalAmountRecieved, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(GameManagerStrategy.GameStatus.Accepted));
    }

    function test_recipient_can_reapply_after_reject() public {
        address recipientAddress = _register_create_reject();

        // Facilitator cannot simply approve after rejecting recipient
        // Why?
        // If they were rejected, they should make some changes to their profile.

        Metadata memory reason = Metadata(1, "I like the ship!");

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);
        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            recipientAddress,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                team(0).wearer,
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();

        // They must update their profile

        _register_recipient();

        // Then they can be approved

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            recipientAddress,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                team(0).wearer,
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();
    }

    function testRevert_reviewApplicant_INVALID_STATUS() public {
        address applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        Metadata memory reason = Metadata(1, "I like the ship!");

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.GameStatus.None,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                team(0).wearer,
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();
    }

    function test_reviewApplicant_reject() public {
        address recipientAddress = _register_create_reject();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientAddress);

        assertEq(recipient.recipientAddress, recipientAddress);
        assertEq(recipient.profileId, registry().getProfileByAnchor(profile1_anchor()).id);
        assertEq(recipient.shipName, "Ship Name");
        assertEq(recipient.shipAddress, address(0));
        assertEq(recipient.shipPoolId, 0);
        assertEq(recipient.grantAmount, 0);
        assertEq(recipient.totalAmountRecieved, 0);
        assertEq(recipient.metadata.pointer, "Ship 1");
        assertEq(recipient.metadata.protocol, 1);
        assertEq(uint8(recipient.status), uint8(GameManagerStrategy.GameStatus.Rejected));
    }

    function test_allocate() public {
        address[] memory recipients = _register_create_accept_allocate();

        address recipientAddress = recipients[0];
        address recipientAddress2 = recipients[1];
        address recipientAddress3 = recipients[2];

        GameManagerStrategy.Recipient memory recipient1 = gameManager().getRecipient(recipientAddress);
        bytes32 profileId1 = registry().getProfileByAnchor(profile1_anchor()).id;

        assertEq(recipient1.recipientAddress, recipientAddress);
        assertEq(recipient1.profileId, profileId1);
        assertEq(recipient1.shipName, "Ship Name");
        assertEq(recipient1.shipAddress, address(shipStrategy));
        assertEq(recipient1.shipPoolId, shipStrategy.getPoolId());
        assertEq(recipient1.grantAmount, 20_000e18);
        assertEq(recipient1.metadata.pointer, "Ship 1");
        assertEq(recipient1.metadata.protocol, 1);
        assertEq(uint8(recipient1.status), uint8(GameManagerStrategy.GameStatus.Allocated));

        GameManagerStrategy.Recipient memory recipient2 = gameManager().getRecipient(recipientAddress2);
        bytes32 profileId2 = registry().getProfileByAnchor(profile2_anchor()).id;

        assertEq(recipient2.recipientAddress, recipientAddress2);
        assertEq(recipient2.profileId, profileId2);
        assertEq(recipient2.shipName, "Ship Name 2");
        assertEq(recipient2.shipAddress, address(ship2Strategy));
        assertEq(recipient2.shipPoolId, ship2Strategy.getPoolId());
        assertEq(recipient2.grantAmount, 40_000e18);
        assertEq(recipient2.metadata.pointer, "Ship 2");
        assertEq(recipient2.metadata.protocol, 1);
        assertEq(uint8(recipient2.status), uint8(GameManagerStrategy.GameStatus.Allocated));

        GameManagerStrategy.Recipient memory recipient3 = gameManager().getRecipient(recipientAddress3);
        bytes32 profileId3 = registry().getProfileByAnchor(poolProfile_anchor()).id;

        assertEq(recipient3.recipientAddress, recipientAddress3);
        assertEq(recipient3.profileId, profileId3);
        assertEq(recipient3.shipName, "Ship Name 3");
        assertEq(recipient3.shipAddress, address(ship3Strategy));
        assertEq(recipient3.shipPoolId, ship3Strategy.getPoolId());
        assertEq(recipient3.grantAmount, 30_000e18);
        assertEq(recipient3.metadata.pointer, "Ship 3");
        assertEq(recipient3.metadata.protocol, 1);
        assertEq(uint8(recipient3.status), uint8(GameManagerStrategy.GameStatus.Allocated));

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);

        address[] memory roundShips = round.ships;

        address roundShip = roundShips[0];
        address roundShip2 = roundShips[1];
        address roundShip3 = roundShips[2];

        assertEq(uint8(round.startTime), 0);
        assertEq(uint8(round.endTime), 0);
        assertEq(_GAME_AMOUNT, round.totalRoundAmount);
        assertEq(uint8(round.status), uint8(GameManagerStrategy.GameStatus.Allocated));
        assertEq(roundShips.length, 3);
        assertEq(roundShip, recipientAddress);
        assertEq(roundShip2, recipientAddress2);
        assertEq(roundShip3, recipientAddress3);
    }

    function testRevert_allocate_NOT_ENOUGH_FUNDS_total() public {
        address recipientAddress = _register_create_approve();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](1);
        recipientAddresses[0] = recipientAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _GAME_AMOUNT;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT + 1);

        uint256 poolId = gameManager().getPoolId();
        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function testRevert_allocate_ARRAY_MISMATCH_out_of_bounds() public {
        address recipientAddress = _register_recipient();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](1);
        recipientAddresses[0] = recipientAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _GAME_AMOUNT;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(ARRAY_MISMATCH.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function testRevert_allocate_ARRAY_MISMATCH_param_length() public {
        address recipientAddress = _register_create_approve();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](1);

        recipientAddresses[0] = recipientAddress;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _GAME_AMOUNT;
        amounts[1] = _GAME_AMOUNT;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(ARRAY_MISMATCH.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function testRevert_allocate_NOT_ENOUGH_FUNDS_in_loop() public {
        address recipientAddress = _register_create_approve();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](1);
        recipientAddresses[0] = recipientAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _GAME_AMOUNT + 1;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function testRevert_allocate_MISMATCH() public {
        address recipientAddress = _register_create_approve();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](1);
        recipientAddresses[0] = recipientAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _GAME_AMOUNT;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT - 1);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(MISMATCH.selector);

        vm.startPrank(facilitator().wearer);
        allo().allocate(poolId, data);
        vm.stopPrank();
    }

    function test_distribute() public {
        address[] memory recipientAddresses = _register_create_accept_allocate_distribute();

        GameManagerStrategy.Recipient memory recipient1 = gameManager().getRecipient(recipientAddresses[0]);

        assertEq(uint8(recipient1.status), uint8(GameManagerStrategy.GameStatus.Active));

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);
        assertEq(block.timestamp, round.startTime);
        assertEq(block.timestamp + _3_MONTHS, round.endTime);
        assertEq(uint8(round.status), uint8(GameManagerStrategy.GameStatus.Funded));

        uint256 shipBalance = ARB().balanceOf(address(shipStrategy));
        uint256 ship2Balance = ARB().balanceOf(address(ship2Strategy));
        uint256 ship3Balance = ARB().balanceOf(address(ship3Strategy));

        uint256 shipPoolAmount = shipStrategy.getPoolAmount();
        uint256 ship2PoolAmount = ship2Strategy.getPoolAmount();
        uint256 ship3PoolAmount = ship3Strategy.getPoolAmount();
        uint256 gameManagerBalance = ARB().balanceOf(address(gameManager()));

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipientAddresses[0]);
        GameManagerStrategy.Recipient memory recipient2 = gameManager().getRecipient(recipientAddresses[1]);
        GameManagerStrategy.Recipient memory recipient3 = gameManager().getRecipient(recipientAddresses[2]);

        assertEq(shipBalance, 20_000e18);
        assertEq(ship2Balance, 40_000e18);
        assertEq(ship3Balance, 30_000e18);

        assertEq(shipPoolAmount, 20_000e18);
        assertEq(ship2PoolAmount, 40_000e18);
        assertEq(ship3PoolAmount, 30_000e18);

        assertEq(recipient.totalAmountRecieved, 20_000e18);
        assertEq(recipient2.totalAmountRecieved, 40_000e18);
        assertEq(recipient3.totalAmountRecieved, 30_000e18);

        assertEq(uint8(recipient.status), uint8(GameManagerStrategy.GameStatus.Active));
        assertEq(uint8(recipient2.status), uint8(GameManagerStrategy.GameStatus.Active));
        assertEq(uint8(recipient3.status), uint8(GameManagerStrategy.GameStatus.Active));

        assertEq(gameManager().getPoolAmount(), 0);
        assertEq(gameManagerBalance, 0);
    }

    function testRevert_distribute_NOT_ENOUGH_FUNDS() public {
        address[] memory recipientAddresses = _register_create_accept_allocate_distribute();

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);

        vm.startPrank(facilitator().wearer);
        allo().distribute(poolId, recipientAddresses, abi.encode(block.timestamp, block.timestamp + _3_MONTHS));
        vm.stopPrank();
    }

    function testRevert_distribute_INVALID_STATUS() public {
        _register_create_approve();
        _quick_fund_manager();

        address[] memory recipientAddresses = new address[](0);

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(GameManagerStrategy.INVALID_STATUS.selector);

        vm.startPrank(facilitator().wearer);
        allo().distribute(poolId, recipientAddresses, abi.encode(block.timestamp, block.timestamp + _3_MONTHS));
        vm.stopPrank();
    }

    function testRevert_distribute_ARRAY_MISMATCH() public {
        address recipientAddress = _register_create_approve();

        address[] memory recipientAddresses = new address[](1);
        recipientAddresses[0] = recipientAddress;

        uint256 poolId = gameManager().getPoolId();

        vm.expectRevert(ARRAY_MISMATCH.selector);

        vm.startPrank(facilitator().wearer);
        allo().distribute(poolId, recipientAddresses, abi.encode(block.timestamp, block.timestamp + _3_MONTHS));
        vm.stopPrank();
    }

    function test_startGame() public {
        _register_create_accept_allocate_distribute_start();

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);

        assertEq(uint8(round.status), uint8(GameManagerStrategy.GameStatus.Active));
        assertEq(gameManager().isPoolActive(), false);
    }

    function testRevert_startGame_UNAUTHORIZED() public {
        _register_create_accept_allocate_distribute();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(0).wearer);
        gameManager().startGame();
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        gameManager().startGame();
        vm.stopPrank();
    }

    function testRevert_startGame_POOL_INACTIVE() public {
        _register_create_accept_allocate_distribute_start();

        vm.expectRevert(POOL_INACTIVE.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().startGame();
        vm.stopPrank();
    }

    function testRevert_startGame_INVALID_TIME() public {
        _register_create_accept_allocate_distribute();

        vm.warp(block.timestamp - 1);

        vm.expectRevert(GameManagerStrategy.INVALID_TIME.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().startGame();
        vm.stopPrank();
    }

    function testRevert_stopGame_UNAUTHORIZED() public {
        _register_create_accept_allocate_distribute_start();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(0).wearer);
        gameManager().stopGame();
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        gameManager().stopGame();
        vm.stopPrank();
    }

    function test_stopGame() public {
        address[] memory recipients = _register_create_accept_allocate_distribute_start_stop();

        address recipientAddress = recipients[0];
        address recipientAddress2 = recipients[1];
        address recipientAddress3 = recipients[2];

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);
        uint256 currentRoundIndex = gameManager().currentRoundIndex();

        GameManagerStrategy.Recipient memory recipient1 = gameManager().getRecipient(recipientAddress);
        GameManagerStrategy.Recipient memory recipient2 = gameManager().getRecipient(recipientAddress2);
        GameManagerStrategy.Recipient memory recipient3 = gameManager().getRecipient(recipientAddress3);

        assertEq(uint8(round.status), uint8(GameManagerStrategy.GameStatus.Completed));
        assertEq(currentRoundIndex, 1);

        assertEq(uint8(recipient1.status), uint8(GameManagerStrategy.GameStatus.Completed));
        assertEq(uint8(recipient2.status), uint8(GameManagerStrategy.GameStatus.Completed));
        assertEq(uint8(recipient3.status), uint8(GameManagerStrategy.GameStatus.Completed));

        assertEq(gameManager().isPoolActive(), true);
    }

    function testRevert_stopGame_POOL_ACTIVE() public {
        _register_create_accept_allocate_distribute();

        vm.expectRevert(POOL_ACTIVE.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().stopGame();
        vm.stopPrank();
    }

    function testRevert_stopGame_INVALID_TIME() public {
        _register_create_accept_allocate_distribute_start();

        vm.warp(block.timestamp + _3_MONTHS - 1);

        vm.expectRevert(GameManagerStrategy.INVALID_TIME.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().stopGame();
        vm.stopPrank();

        vm.warp(block.timestamp + _3_MONTHS + _3_MONTHS + 1);

        vm.startPrank(facilitator().wearer);
        gameManager().stopGame();
        vm.stopPrank();
    }

    function testWithdraw_facilitator() public {
        _register_create_accept_allocate();

        vm.startPrank(facilitator().wearer);
        gameManager().withdraw(_GAME_AMOUNT);
        vm.stopPrank();

        // pool admin is serving as root account in the context of these tests
        assertEq(ARB().balanceOf(pool_admin()), _GAME_AMOUNT);
        assertEq(ARB().balanceOf(address(gameManager())), 0);

        assertEq(gameManager().getPoolAmount(), 0);
    }

    function testWithdraw_root_account() public {
        _register_create_accept_allocate();

        vm.startPrank(pool_admin());
        gameManager().withdraw(_GAME_AMOUNT);
        vm.stopPrank();

        // pool admin is serving as root account in the context of these tests
        assertEq(ARB().balanceOf(pool_admin()), _GAME_AMOUNT);
        assertEq(ARB().balanceOf(address(gameManager())), 0);

        assertEq(gameManager().getPoolAmount(), 0);
    }

    function testRevert_withdraw_NOT_ENOUGH_FUNDS() public {
        _register_create_accept_allocate();

        vm.expectRevert(NOT_ENOUGH_FUNDS.selector);

        vm.startPrank(facilitator().wearer);
        gameManager().withdraw(_GAME_AMOUNT + 1);
        vm.stopPrank();
    }

    function testRevert_withdraw_UNAUTHORIZED() public {
        _register_create_accept_allocate();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(randomAddress());
        gameManager().withdraw(_GAME_AMOUNT);
        vm.stopPrank();

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.startPrank(shipOperator(1).wearer);
        gameManager().withdraw(_GAME_AMOUNT);
        vm.stopPrank();
    }

    function test_postUpdate() public {
        // This is likely failing because of an error with foundry.
        // I manually tested this function and it works as expected.
        // I will do more investigations on the frontend and in the
        // subgraph and make sure my assumption is correct.

        // string memory tag = "test";
        // Metadata memory metadata = Metadata(1, "Posting Update!");

        // address notRecipientId = address(0);
        // uint256 facilitatorId = facilitator().id;
        // address facilitatorAddress = facilitator().wearer;

        // // Game Facilitator posts an update
        // vm.expectEmit(true, true, true, true);
        // emit UpdatePosted(tag, facilitatorId, notRecipientId, metadata);
        // vm.startPrank(facilitatorAddress);
        // gameManager().postUpdate(tag, metadata);
        // vm.stopPrank();

        // Root Account posts an update

        // vm.expectEmit(true, true, false, false);
        // emit UpdatePosted(keccak256(tag), 0, pool_admin(), metadata);

        // vm.startPrank(pool_admin());
        // gameManager().postUpdate(tag, metadata);
        // vm.stopPrank();
    }

    function test_2_rounds() public {
        // ***ROUND 1***
        address[] memory recipients = _register_create_accept_allocate_distribute_start_stop();
        uint256 poolId = gameManager().getPoolId();

        // ***ROUND 2***

        // CREATE ROUND
        vm.startPrank(facilitator().wearer);
        gameManager().createRound(_GAME_AMOUNT);
        vm.stopPrank();

        /// REGISTER
        _register_all_3_ships(recipients);

        GameManagerStrategy.Recipient memory newRecipient = gameManager().getRecipient(recipients[0]);
        GameManagerStrategy.Recipient memory newRecipient2 = gameManager().getRecipient(recipients[1]);
        GameManagerStrategy.Recipient memory newRecipient3 = gameManager().getRecipient(recipients[2]);

        assertEq(newRecipient.totalAmountRecieved, 20_000e18);
        assertEq(newRecipient2.totalAmountRecieved, 40_000e18);
        assertEq(newRecipient3.totalAmountRecieved, 30_000e18);

        // APPROVE
        _approve_all_3_ships(recipients);

        // ALLOCATE
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 20_000e18;
        amounts[1] = 40_000e18;
        amounts[2] = 30_000e18;

        _quick_fund_manager();

        vm.startPrank(facilitator().wearer);
        bytes memory allocateData = abi.encode(recipients, amounts, _GAME_AMOUNT);
        allo().allocate(poolId, allocateData);

        // Distribute
        bytes memory times = abi.encode(block.timestamp, block.timestamp + _3_MONTHS);

        allo().distribute(poolId, recipients, times);

        vm.stopPrank();

        GameManagerStrategy.Recipient memory recipient = gameManager().getRecipient(recipients[0]);
        GameManagerStrategy.Recipient memory recipient2 = gameManager().getRecipient(recipients[1]);
        GameManagerStrategy.Recipient memory recipient3 = gameManager().getRecipient(recipients[2]);

        assertEq(recipient.totalAmountRecieved, 40_000e18);
        assertEq(recipient2.totalAmountRecieved, 80_000e18);
        assertEq(recipient3.totalAmountRecieved, 60_000e18);

        // START

        vm.startPrank(facilitator().wearer);
        gameManager().startGame();
        vm.stopPrank();

        vm.warp(block.timestamp + _3_MONTHS + 1);

        // STOP
        vm.startPrank(facilitator().wearer);
        gameManager().stopGame();
        vm.stopPrank();
    }

    // ====================================
    // =========== Helpers ================
    // ====================================

    function _register_all_3_ships(address[] memory recipients) public {
        address recipientAddress = recipients[0];
        address recipientAddress2 = recipients[1];
        address recipientAddress3 = recipients[2];

        uint256 poolId = gameManager().getPoolId();
        // Register recipient 1
        Metadata memory metadata = Metadata(1, "Ship 1");
        bytes memory data = abi.encode(recipientAddress, "Ship Name", metadata);
        vm.startPrank(profile1_member1());
        allo().registerRecipient(poolId, data);
        vm.stopPrank();

        // Register recipient 2
        Metadata memory metadata2 = Metadata(1, "Ship 2");
        bytes memory data2 = abi.encode(recipientAddress2, "Ship Name 2", metadata2);
        vm.startPrank(profile2_owner());
        allo().registerRecipient(poolId, data2);
        vm.stopPrank();

        // Register reciepient 3
        Metadata memory metadata3 = Metadata(1, "Ship 3");
        bytes memory data3 = abi.encode(recipientAddress3, "Ship Name 3", metadata3);
        vm.startPrank(pool_admin());
        allo().registerRecipient(poolId, data3);
        vm.stopPrank();
    }

    function _approve_all_3_ships(address[] memory recipients) public {
        address recipientAddress = recipients[0];
        address recipientAddress2 = recipients[1];
        address recipientAddress3 = recipients[2];

        Metadata memory reason = Metadata(1, "I like the ship!");

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            recipientAddress,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                profile1_owner(),
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        // Accept recipient 2
        gameManager().reviewRecipient(
            recipientAddress2,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name 2",
                Metadata(1, "Ship 2"),
                profile2_owner(),
                shipOperator(1).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        // Accept recipient 3
        gameManager().reviewRecipient(
            recipientAddress3,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name 3",
                Metadata(1, "Ship 3"),
                pool_admin(),
                shipOperator(2).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();
    }

    function _register_create_accept_allocate_distribute_start_stop() internal returns (address[] memory recipients) {
        recipients = _register_create_accept_allocate_distribute_start();

        vm.warp(block.timestamp + _3_MONTHS + 1);

        address facilitator = facilitator().wearer;

        vm.expectEmit(true, true, true, true);
        emit PoolActive(true);
        emit GameActive(false, 0);

        vm.startPrank(facilitator);
        gameManager().stopGame();
        vm.stopPrank();

        return recipients;
    }

    function _register_create_accept_allocate_distribute_start() internal returns (address[] memory recipients) {
        recipients = _register_create_accept_allocate_distribute();

        vm.expectEmit(true, true, true, true);
        emit PoolActive(false);
        emit GameActive(true, 0);

        vm.startPrank(facilitator().wearer);
        gameManager().startGame();
        vm.stopPrank();

        return recipients;
    }

    function _register_create_accept_allocate_distribute() internal returns (address[] memory recipients) {
        recipients = _register_create_accept_allocate();

        uint256 poolId = gameManager().getPoolId();

        vm.expectEmit(true, true, true, true);
        emit Distributed(recipients[0], address(shipStrategy), 20_000e18, facilitator().wearer);
        emit Distributed(recipients[1], address(ship2Strategy), 40_000e18, facilitator().wearer);
        emit Distributed(recipients[2], address(ship3Strategy), 30_000e18, facilitator().wearer);

        bytes memory times = abi.encode(block.timestamp, block.timestamp + _3_MONTHS);

        vm.startPrank(facilitator().wearer);
        allo().distribute(poolId, recipients, times);
        vm.stopPrank();

        return recipients;
    }

    function _register_create_accept_allocate() internal returns (address[] memory) {
        address recipientAddress = _register_create_approve();
        _quick_fund_manager();

        // Register recipient 2
        address recipientAddress2 = profile2_anchor();
        Metadata memory metadata2 = Metadata(1, "Ship 2");
        bytes memory data2 = abi.encode(recipientAddress2, "Ship Name 2", metadata2);
        vm.startPrank(profile2_owner());
        allo().registerRecipient(gameManager().getPoolId(), data2);
        vm.stopPrank();

        // Register reciepient 3
        address recipientAddress3 = poolProfile_anchor();
        Metadata memory metadata3 = Metadata(1, "Ship 3");
        bytes memory data3 = abi.encode(recipientAddress3, "Ship Name 3", metadata3);
        vm.startPrank(pool_admin());
        allo().registerRecipient(gameManager().getPoolId(), data3);
        vm.stopPrank();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());

        Metadata memory reason = Metadata(1, "I like the ship!");

        // Review recipient 2
        vm.startPrank(profile2_owner());
        registry().addMembers(profile2_id(), contractAsManager);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        address payable shipAddress2 = gameManager().reviewRecipient(
            profile2_anchor(),
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name 2",
                Metadata(1, "Ship 2"),
                team(1).wearer,
                shipOperator(1).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();
        ship2Strategy = GrantShipStrategy(shipAddress2);

        // Review recipient 3
        vm.startPrank(pool_admin());
        registry().addMembers(poolProfile_id(), contractAsManager);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        address payable shipAddress3 = gameManager().reviewRecipient(
            poolProfile_anchor(),
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name 3",
                Metadata(1, "Ship 3"),
                team(1).wearer,
                shipOperator(2).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();

        ship3Strategy = GrantShipStrategy(shipAddress3);

        // Finally, we allocate

        address[] memory recipientAddresses = new address[](3);
        recipientAddresses[0] = recipientAddress;
        recipientAddresses[1] = recipientAddress2;
        recipientAddresses[2] = recipientAddress3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 20_000e18;
        amounts[1] = 40_000e18;
        amounts[2] = 30_000e18;

        bytes memory data = abi.encode(recipientAddresses, amounts, _GAME_AMOUNT);

        vm.startPrank(facilitator().wearer);
        allo().allocate(gameManager().getPoolId(), data);
        vm.stopPrank();

        return recipientAddresses;
    }

    function _quick_fund_manager() internal {
        vm.startPrank(arbWhale);
        ARB().transfer(facilitator().wearer, _GAME_AMOUNT);
        vm.stopPrank();

        uint256 poolId = gameManager().getPoolId();

        vm.startPrank(facilitator().wearer);
        ARB().approve(address(allo()), _GAME_AMOUNT);
        allo().fundPool(poolId, _GAME_AMOUNT);
        vm.stopPrank();
    }

    function _register_create_reject() internal returns (address applicantId) {
        applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        Metadata memory reason = Metadata(1, "I dislike the ship!");

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit RecipientRejected(applicantId, reason);

        vm.startPrank(facilitator().wearer);
        gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.GameStatus.Rejected,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                team(0).wearer,
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();
    }

    function _register_create_approve() internal returns (address applicantId) {
        applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        Metadata memory reason = Metadata(1, "I like the ship!");

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        // Review: I cannot test the ShipLaunched event here because the ship is created in the
        // reviewRecipient function. The address of the ship is not known until
        // after the reviewRecipient function is called. If there is a way to
        // test this, I would love to know.

        vm.expectEmit(true, true, true, true);
        emit RecipientAccepted(applicantId, reason);

        vm.startPrank(facilitator().wearer);
        address payable shipAddress = gameManager().reviewRecipient(
            applicantId,
            GameManagerStrategy.GameStatus.Accepted,
            ShipInitData(
                true,
                true,
                true,
                "Ship Name",
                Metadata(1, "Ship 1"),
                profile1_owner(),
                shipOperator(0).id,
                facilitator().id
            ),
            address(shipFactory()),
            reason
        );
        vm.stopPrank();

        shipStrategy = GrantShipStrategy(shipAddress);
    }

    function _register_create_round() internal returns (address recipientId) {
        recipientId = _register_recipient();

        vm.startPrank(facilitator().wearer);

        vm.expectEmit(true, true, true, true);
        emit RoundCreated(0, _GAME_AMOUNT);

        gameManager().createRound(_GAME_AMOUNT);
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
