// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Strategy contracts
import {GrantShipStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";

// Internal libraries
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../../shared/AlloSetup.sol";

import {GameManagerSetup} from "./GameManagerSetup.t.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {EventSetup} from "../../shared/EventSetup.sol";

//Todo Test if each contract inherits a different version of the same contract
// Is this contract getting the same address that others recieve.
contract GrantShiptStrategyTest is Test, GameManagerSetup, Native, EventSetup, Errors {
    // ================= Setup =====================

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __GameSetup();
    }

    // ================= Deployment & Init Tests =====================

    function test_deploy_manager() public {
        assertTrue(address(gameManager) != address(0));
        assertTrue(address(gameManager.getAllo()) == address(allo()));
        assertTrue(gameManager.getStrategyId() == keccak256(abi.encode(gameManagerStrategyId)));
    }

    function test_init_manager() public {
        assertTrue(gameManager.currentRoundId() == 0);
        assertTrue(gameManager.currentRoundStartTime() == 0);
        assertTrue(gameManager.currentRoundEndTime() == 0);
        assertTrue(gameManager.currentRoundStatus() == IStrategy.Status.None);
        assertTrue(gameManager.token() == address(arbToken));
        assertTrue(gameManager.gameFacilitatorHatId() == facilitator().id);
    }

    function test_ships_created() public {
        //Todo add tests for other params once they are added to Ship Strategy
        //Todo add tests for a second Grant Ship Strategy

        address[] memory _teamAddresses = new address[](3);

        _teamAddresses[0] = ship(0).wearer;
        _teamAddresses[1] = ship(1).wearer;
        _teamAddresses[2] = ship(2).wearer;

        for (uint256 i = 0; i < _teamAddresses.length;) {
            _test_ship_created(_teamAddresses[i]);
            unchecked {
                i++;
            }
        }
    }

    // ================= Helpers ===================
    function __createGameManager(uint256 _gameFacilitatorId, address _token, address _hatsAddress)
        internal
        returns (uint256 newPoolId)
    {
        //@Todo: Refactor to its own test contract
        gameManager = new GameManagerStrategy(address(allo()), gameManagerStrategyId);

        vm.prank(pool_admin());
        arbToken.approve(address(allo()), 90_000e18);

        bytes[] memory _shipData = new bytes[](3);

        _shipData[0] = abi.encode("Grant Ship 1", Metadata(1, "grant-ship-1-data"), ship(0).wearer);
        _shipData[1] = abi.encode("Grant Ship 2", Metadata(1, "grant-ship-2-data"), ship(1).wearer);
        _shipData[2] = abi.encode("Grant Ship 3", Metadata(1, "grant-ship-2-data"), ship(2).wearer);

        vm.startPrank(pool_admin());
        newPoolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(gameManager),
            abi.encode(abi.encode(_gameFacilitatorId, _token, _hatsAddress, pool_admin()), _shipData),
            _token,
            90_000e18,
            Metadata(1, "game-controller-data"),
            // pool manager/game facilitator role will be mediated through Hats Protocol
            // pool_admin address will be the game_facilitator multisig
            // using pool_admin as a single address for both roles
            noManagers
        );

        vm.stopPrank();
    }

    function _test_ship_created(address _teamAddress) internal {
        GrantShipStrategy ship1Strategy = _getShipStrategy(_teamAddress);
        assertTrue(address(ship1Strategy.getAllo()) == address(allo()));
        assertTrue(ship1Strategy.getStrategyId() == keccak256(abi.encode("Grant Ship Strategy")));
        assertTrue(ship1Strategy.registryGating());
        assertTrue(ship1Strategy.metadataRequired());
        assertTrue(ship1Strategy.grantAmountRequired());
    }

    function _getShipStrategy(address _teamAddress) internal view returns (GrantShipStrategy) {
        address payable strategyAddress = gameManager.getStrategyAddress(_teamAddress);
        return GrantShipStrategy(strategyAddress);
    }
}