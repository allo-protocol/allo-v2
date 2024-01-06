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
        //Todo add tests for other params once they are added to Ship Strategy
        address[] memory _teamAddresses = new address[](3);

        _teamAddresses[0] = team(0).wearer;
        _teamAddresses[1] = team(1).wearer;
        _teamAddresses[2] = team(2).wearer;

        for (uint256 i = 0; i < _teamAddresses.length;) {
            _test_ship_created(_teamAddresses[i]);
            unchecked {
                i++;
            }
        }
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
        address payable strategyAddress = gameManager().getStrategyAddress(_teamAddress);
        return GrantShipStrategy(strategyAddress);
    }
}
