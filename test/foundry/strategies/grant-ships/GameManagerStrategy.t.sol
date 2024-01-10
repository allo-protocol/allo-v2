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
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";

contract GameManagerStrategyTest is Test, GameManagerSetup, Errors, EventSetup {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    event RoundCreated(uint256 gameIndex, address token, uint256 totalRoundAmount);

    /// ===============================
    /// ========== State ==============
    /// ===============================

    uint256 internal constant _gameAmount = 90_000e18;
    uint256 internal constant _shipAmount = 30_000e18;

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});

        __ManagerSetup();
    }

    function test_registerRecipient() public {
        address recipientId = _register_applicant();

        GameManagerStrategy.Applicant memory applicant = gameManager().getApplicant(recipientId);
        // Check that the recipient was registered
        assertEq(applicant.applicantId, profile1_anchor());
        assertEq(applicant.metadata.pointer, "Ship 1");
        assertEq(applicant.metadata.protocol, 1);
        assertEq(applicant.shipName, "Ship Name");
        assertEq(uint8(applicant.status), uint8(IStrategy.Status.Pending));
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
        address applicantId = _register_applicant();

        Metadata memory metadata = Metadata(1, "Ship 1: Part 2");

        bytes memory data = abi.encode(applicantId, "Ship Name: Part 2", metadata);

        uint256 poolId = gameManager().getPoolId();

        vm.startPrank(profile1_member1());
        allo().registerRecipient(poolId, data);
        vm.stopPrank();

        GameManagerStrategy.Applicant memory newApplicant = gameManager().getApplicant(applicantId);
        assertEq(newApplicant.applicantId, profile1_anchor());
        assertEq(newApplicant.metadata.pointer, "Ship 1: Part 2");
        assertEq(newApplicant.metadata.protocol, 1);
        assertEq(uint8(newApplicant.status), uint8(IStrategy.Status.Pending));
        assertEq(newApplicant.shipName, "Ship Name: Part 2");
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

    function testApproveApplicant() public {
        address applicantId = register_create_approve();

        GameManagerStrategy.Applicant memory applicant = gameManager().getApplicant(applicantId);

        assertEq(uint8(applicant.status), uint8(IStrategy.Status.Accepted));
    }

    // ====================================
    // =========== Helpers ================
    // ====================================

    function register_create_approve() internal returns (address applicantId) {
        applicantId = _register_create_round();

        address[] memory contractAsManager = new address[](1);
        contractAsManager[0] = address(gameManager());
        bytes32 profileId = registry().getProfileByAnchor(profile1_anchor()).id;

        vm.startPrank(profile1_owner());
        registry().addMembers(profileId, contractAsManager);
        vm.stopPrank();

        vm.startPrank(facilitator().wearer);
        gameManager().reviewApplicant(
            applicantId,
            IStrategy.Status.Accepted,
            ShipInitData(true, true, true, "Ship Name", Metadata(1, "Ship 1"), team(0).wearer, shipOperator(0).id)
        );
        vm.stopPrank();
    }

    function _register_create_round() internal returns (address applicantId) {
        applicantId = _register_applicant();

        address arbAddress = address(ARB());

        vm.startPrank(facilitator().wearer);

        vm.expectEmit(false, false, false, false);
        emit RoundCreated(0, arbAddress, _gameAmount);

        gameManager().createRound(_gameAmount, arbAddress);
        vm.stopPrank();

        GameManagerStrategy.GameRound memory round = gameManager().getGameRound(0);

        assertEq(_gameAmount, round.totalRoundAmount);
        assertEq(address(ARB()), round.token);
    }

    function _register_applicant_return_data() internal returns (address applicantId, bytes memory data) {
        applicantId = profile1_anchor();

        Metadata memory metadata = Metadata(1, "Ship 1");

        data = abi.encode(applicantId, "Ship Name", metadata);

        vm.expectEmit(true, true, true, true);
        emit Registered(applicantId, data, profile1_member1());

        vm.startPrank(profile1_member1());
        allo().registerRecipient(gameManager().getPoolId(), data);
        vm.stopPrank();
    }

    function _register_applicant() internal returns (address applicantId) {
        (applicantId,) = _register_applicant_return_data();
    }
}
