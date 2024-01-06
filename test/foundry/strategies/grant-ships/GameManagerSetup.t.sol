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
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";

contract GameManagerSetup is Test, HatsSetupLive, AlloSetup, RegistrySetupFullLive {
    /////////////////GAME MANAGER///////////////
    GameManagerStrategy internal _gameManager;
    uint256 public gameManagerPoolId;

    string public gameManagerStrategyId = "GameManagerStrategy";

    ////////////////GRANT SHIPS/////////////////
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

    function gameManager() public view returns (GameManagerStrategy) {
        return _gameManager;
    }

    function ship(uint256 _index) public view returns (GrantShipStrategy) {
        return _ships[_index];
    }

    function shipSetupData(uint256 _index) public view returns (bytes memory) {
        return _shipSetupData[_index];
    }

    // ====================================
    // =========== Setup ==================
    // ====================================

    function __GameSetup() internal {
        __generateShipData();
        __initGameManager();
        __dealArb();
        __createGameManager();
        __storeShips();
    }

    function __generateShipData() internal {
        for (uint32 i = 0; i < _shipSetupData.length;) {
            ShipInitData memory shipInitData = ShipInitData(
                true,
                true,
                true,
                string.concat("Ship ", vm.toString(uint256(i))),
                Metadata(1, string.concat("ipfs://grant-ships/ship.json/", vm.toString(i))),
                team(i).wearer,
                shipOperator(i).id
            );

            //Todo there will be more setup params once the strategy design is finalized
            _shipSetupData[i] = abi.encode(shipInitData);
            unchecked {
                i++;
            }
        }
    }

    function __initGameManager() internal {
        _gameManager = new GameManagerStrategy(address(allo()), gameManagerStrategyId);
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
            address(_gameManager),
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

    function __storeShips() internal {
        for (uint32 i = 0; i < _ships.length;) {
            address payable strategyAddress = _gameManager.getStrategyAddress(team(i).wearer);
            _ships[i] = GrantShipStrategy(strategyAddress);
            unchecked {
                i++;
            }
        }
    }
}
