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
import {Native} from "../../../../contracts/core/libraries/Native.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {Accounts} from "../../shared/Accounts.sol";
import {ShipInitData} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipShared.sol";

contract GameManagerSetup is Test, HatsSetupLive, AlloSetup, RegistrySetupFullLive, Native {
    struct ShipProfile {
        bytes32 id;
        address anchor;
    }

    //     /////////////////GAME MANAGER///////////////
    GameManagerStrategy internal _gameManager;
    uint256 public gameManagerPoolId;
    uint256 internal constant IPFS = 1;

    string public gameManagerStrategyId = "GameManagerStrategy";
    uint32 internal shipAmount;

    //     ////////////////GRANT SHIPS/////////////////
    // bytes[] internal _shipSetupData = new bytes[](3);
    //     GrantShipStrategy[] internal _ships = new GrantShipStrategy[](3);
    ShipProfile[3] internal _shipProfiles;

    //     /////////////////GAME TOKEN/////////////////
    IERC20 public arbToken = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    uint256 internal _manager_pool_amount = 90_000e18;

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

    //     function ship(uint256 _index) public view returns (GrantShipStrategy) {
    //         return _ships[_index];
    //     }

    //     function shipSetupData(uint256 _index) public view returns (bytes memory) {
    //         return _shipSetupData[_index];
    //     }

    function ARB() public view returns (IERC20) {
        return arbToken;
    }

    //     // ====================================
    //     // =========== Setup ==================
    //     // ====================================

    function __GameSetup(uint32 _shipAmount) internal {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __initGameManager();
        __initGameManagerPool();
        __registerShips(_shipAmount);
    }

    function __ManagerSetup() internal {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __initGameManager();
        __initGameManagerPool();
    }

    function __registerShips(uint32 _shipAmount) internal {
        for (uint32 i = 0; i < _shipAmount;) {
            address[] memory managers = new address[](1);
            managers[0] = shipOperator(i).wearer;

            vm.startPrank(team(i).wearer);

            // Create profile with Hats Team Address And ID as Owner
            bytes32 profileId = _registry_.createProfile(
                i,
                string.concat("Ship Profile ", vm.toString(i)),
                Metadata({protocol: 1, pointer: string.concat("ipfs://ship-profile/", vm.toString(i))}),
                team(i).wearer,
                managers
            );

            address profileAnchor = _registry_.getProfileById(profileId).anchor;

            // Save profiles for easy testing later on
            ShipProfile storage currentShipProfile = _shipProfiles[i];

            currentShipProfile.id = profileId;
            currentShipProfile.anchor = profileAnchor;

            Metadata memory applicantMetadata =
                Metadata(1, string.concat("ipfs://grant-ships/applicant/", vm.toString(i)));

            // Register Hats Branch/Profile as a recipient
            allo().registerRecipient(
                _gameManager.getPoolId(),
                abi.encode(profileAnchor, string.concat("Ship ", vm.toString(i)), applicantMetadata)
            );
            vm.stopPrank();

            unchecked {
                i++;
            }
        }
    }

    //     function __generateShipData() internal {
    //         for (uint32 i = 0; i < _shipSetupData.length;) {
    //             ShipInitData memory shipInitData = ShipInitData(
    //                 true,
    //                 true,
    //                 true,
    //                 string.concat("Ship ", vm.toString(uint256(i))),
    //                 Metadata(1, string.concat("ipfs://grant-ships/ship.json/", vm.toString(i))),
    //                 team(i).wearer,
    //                 shipOperator(i).id
    //             );

    //             //Todo there will be more setup params once the strategy design is finalized
    //             _shipSetupData[i] = abi.encode(shipInitData);
    //             unchecked {
    //                 i++;
    //             }
    //         }
    //     }

    function __initGameManager() internal {
        _gameManager = new GameManagerStrategy(address(allo()), gameManagerStrategyId);
    }

    //     function __dealArb() internal {
    //         vm.prank(arbWhale);
    //         arbToken.transfer(pool_admin(), _manager_pool_amount);
    //     }

    function __initGameManagerPool() internal {
        vm.startPrank(pool_admin());

        gameManagerPoolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_gameManager),
            abi.encode(facilitator().id, IPFS, address(hats()), pool_admin(), true),
            // Todo: Using native to test multi-token
            // write tests to confirm that this works, otherwise use ARB
            NATIVE,
            0,
            Metadata(IPFS, "ipfs://grant-ships/about.json"),
            // pool manager/game facilitator role will be mediated through Hats Protocol
            // pool_admin address will be the game_facilitator multisig
            // using pool_admin as a single address for both roles
            noManagers
        );

        vm.stopPrank();
    }

    //     function __storeShips() internal {
    //         for (uint32 i = 0; i < _shipSetupData.length;) {
    //             address payable shipAddress = _gameManager.getShipAddress(i);
    //             _ships[i] = GrantShipStrategy(shipAddress);
    //             unchecked {
    //                 i++;
    //             }
    //         }
    //     }
}
