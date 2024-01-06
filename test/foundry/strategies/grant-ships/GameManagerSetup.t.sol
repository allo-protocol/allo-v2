// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Allo} from "../../../../contracts/core/Allo.sol";

// Internal Libraries

import {AlloSetup} from "../../shared/AlloSetup.sol";
import {Accounts} from "../../shared/Accounts.sol";
import {RegistrySetupFullLive} from "../../shared/RegistrySetup.sol";
import {GrantShipStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {Accounts} from "../../shared/Accounts.sol";

contract GameManagerSetup is Test, HatsSetupLive, AlloSetup, RegistrySetupFullLive {
    /////////////////GAME MANAGER///////////////
    GameManagerStrategy public gameManager;
    uint256 gameManagerPoolId;
    string public gameManagerStrategyId = "GameManagerStrategy";

    ////////////////GRANT SHIPS/////////////////
    //Todo there will be more setup params once the strategy design is finalized

    bytes[] internal _shipSetupData = new bytes[](3);
    GrantShipStrategy[] internal _ships = new GrantShipStrategy[](3);

    /////////////////GAME TOKEN/////////////////
    IERC20 public arbToken = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);

    // Binance Hot Wallet on Arbitrum.
    // EOA with lots of ARB for testing live
    address public arbWhale = 0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D;

    /////////////////COMMON////////////////////
    address[] noManagers = new address[](0);

    // ====================================
    // =========== Getters ================
    // ====================================

    // ====================================
    // =========== Setup ==================
    // ====================================

    function __GameSetup() internal {
        __generateShipData();
        __initGameManager();
        __dealArb();
        __createGameManager();
    }

    function __generateShipData() internal {
        for (uint32 i = 0; i < _shipSetupData.length;) {
            _shipSetupData[i] = abi.encode(
                string.concat("Ship ", vm.toString(uint256(i))),
                Metadata(1, string.concat("ipfs://grant-ships/ship.json/", vm.toString(i))),
                ship(i).wearer
            );
            unchecked {
                i++;
            }
        }
    }

    function __initGameManager() internal {
        gameManager = new GameManagerStrategy(address(allo()), gameManagerStrategyId);
    }

    function __dealArb() internal {
        vm.prank(arbWhale);
        arbToken.transfer(pool_admin(), 90_000e18);
    }

    function __createGameManager() internal {
        vm.startPrank(pool_admin());

        arbToken.approve(address(allo()), 90_000e18);

        gameManagerPoolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(gameManager),
            abi.encode(abi.encode(facilitator().id, address(arbToken), address(hats()), pool_admin()), _shipSetupData),
            address(arbToken),
            90_000e18,
            Metadata(1, "game-controller-data"),
            // pool manager/game facilitator role will be mediated through Hats Protocol
            // pool_admin address will be the game_facilitator multisig
            // using pool_admin as a single address for both roles
            noManagers
        );
    }
}
