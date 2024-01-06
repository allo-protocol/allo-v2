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
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";
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
        assertTrue(address(gameManager()) != address(0));
        assertTrue(address(gameManager().getAllo()) == address(allo()));
        assertTrue(gameManager().getStrategyId() == keccak256(abi.encode(gameManagerStrategyId)));
    }

    function test_init_manager() public {
        assertTrue(gameManager().currentRoundId() == 0);
        assertTrue(gameManager().currentRoundStartTime() == 0);
        assertTrue(gameManager().currentRoundEndTime() == 0);
        assertTrue(gameManager().currentRoundStatus() == IStrategy.Status.None);
        assertTrue(gameManager().token() == address(arbToken));
        assertTrue(gameManager().gameFacilitatorHatId() == facilitator().id);
    }

    function test_ships_created() public {
        for (uint256 i = 0; i < 3;) {
            _test_ship_created(i);
            unchecked {
                i++;
            }
        }
    }

    function _test_ship_created(uint256 _shipId) internal {
        GrantShipStrategy shipStrategy = _getShipStrategy(_shipId);
        ShipInitData memory shipInitData = abi.decode(shipSetupData(_shipId), (ShipInitData));
        assertTrue(address(shipStrategy.getAllo()) == address(allo()));
        assertTrue(shipStrategy.getStrategyId() == keccak256(abi.encode(shipInitData.shipName)));
        assertTrue(shipStrategy.registryGating());
        assertTrue(shipStrategy.metadataRequired());
        assertTrue(shipStrategy.grantAmountRequired());
        assertTrue(shipInitData.operatorHatId == shipStrategy.operatorHatId());
        // Todo add tests for other params once they are added to Ship Strategy
    }

    function _getShipStrategy(uint256 _shipId) internal view returns (GrantShipStrategy) {
        address payable strategyAddress = gameManager().getShipAddress(_shipId);
        return GrantShipStrategy(strategyAddress);
    }
}
