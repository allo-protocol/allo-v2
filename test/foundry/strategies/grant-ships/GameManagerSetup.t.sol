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
import {GrantShipFactory} from "../../../../contracts/strategies/_poc/grant-ships/libraries/GrantShipFactory.sol";

contract GameManagerSetup is Test, HatsSetupLive, AlloSetup, RegistrySetupFullLive, Native {
    //     /////////////////GAME MANAGER///////////////
    GameManagerStrategy internal _gameManager;
    uint256 public gameManagerPoolId;
    uint256 internal constant IPFS = 1;

    uint256 internal constant _3_MONTHS = 7889400;
    uint256 internal constant _GAME_AMOUNT = 90_000e18;
    uint256 internal constant _SHIP_AMOUNT = 30_000e18;

    string public gameManagerStrategyId = "GameManagerStrategy";
    uint32 internal shipAmount;

    GrantShipFactory internal _shipFactory;
    ////////////////GRANT SHIPS/////////////////
    ShipInitData[] internal _shipSetupData;
    GrantShipStrategy[] internal _ships;
    GrantShipStrategy internal _shipImpl;

    address[] internal _shipAnchor;
    bytes32[] internal _shipProfileId;

    /////////////////GAME TOKEN/////////////////
    IERC20 public arbToken = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    uint256 internal gameAmount = 90_000e18;

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

    function shipSetupData(uint256 _index) public view returns (ShipInitData memory) {
        return _shipSetupData[_index];
    }

    function shipImpl() public view returns (GrantShipStrategy) {
        return _shipImpl;
    }

    function shipFactory() public view returns (GrantShipFactory) {
        return _shipFactory;
    }

    function ARB() public view returns (IERC20) {
        return arbToken;
    }

    function shipAnchor(uint256 _index) public view returns (address) {
        return _shipAnchor[_index];
    }

    function shipProfileId(uint256 _index) public view returns (bytes32) {
        return _shipProfileId[_index];
    }

    // ====================================
    // =========== Setup ==================
    // ====================================

    function __GameSetup() internal {
        /// Note: This setup is used for testing the GrantShipStrategies
        /// It includes the full manager setup, all the way

        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive();
        __initGameManager();
        __initFactory();
        __initGameManagerPool();
        __generateShipData();
        __registerShips();
        __allocate_distribute_start();
    }

    function __ManagerSetup() internal {
        /// Note: This setup is used for testing the GameManagerStrategy

        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive();
        __initGameManager();
        __initFactory();
        __initGameManagerPool();
    }

    function __registerShips() internal {
        vm.startPrank(facilitator().wearer);
        gameManager().createRound(gameAmount);
        vm.stopPrank();

        for (uint32 i = 0; i < 3;) {
            address[] memory managers = new address[](1);
            // managers[0] = address(gameManager());
            managers[0] = shipOperator(i).wearer;

            vm.startPrank(shipOperator(i).wearer);
            // Create profile with Hats Team Address And ID as Owner
            bytes32 profileId = _registry_.createProfile(
                i + 50,
                string.concat("Ship Profile ", vm.toString(i)),
                Metadata({protocol: 1, pointer: string.concat("ipfs://ship-profile/", vm.toString(i))}),
                shipOperator(i).wearer,
                managers
            );

            address profileAnchor = _registry_.getProfileById(profileId).anchor;

            // Save profiles for easy testing later on
            _shipProfileId.push(profileId);
            _shipAnchor.push(profileAnchor);

            Metadata memory applicantMetadata =
                Metadata(1, string.concat("ipfs://grant-ships/applicant/", vm.toString(i)));

            // Register HatsBranch/Profile as a recipient
            allo().registerRecipient(
                _gameManager.getPoolId(),
                abi.encode(profileAnchor, string.concat("Ship ", vm.toString(i)), applicantMetadata)
            );

            vm.stopPrank();

            Metadata memory reason = Metadata(1, "I like the ship!");

            vm.startPrank(facilitator().wearer);
            address payable shipAddress = gameManager().reviewRecipient(
                profileAnchor,
                GameManagerStrategy.GameStatus.Accepted,
                _shipSetupData[i],
                address(shipFactory()),
                reason
            );
            vm.stopPrank();

            _ships.push(GrantShipStrategy(shipAddress));

            unchecked {
                i++;
            }
        }
    }

    function __allocate_distribute_start() internal {
        // ARB Whale sends ARB to a game facilitator
        uint256 poolId = gameManager().getPoolId();
        vm.startPrank(arbWhale);
        ARB().transfer(facilitator().wearer, _GAME_AMOUNT);
        vm.stopPrank();

        // Facilitator approves gameManager to spend ARB
        vm.startPrank(facilitator().wearer);
        ARB().approve(address(allo()), _GAME_AMOUNT);

        // Facilitator approves funds the gameManager Allo pool
        allo().fundPool(poolId, _GAME_AMOUNT);

        uint256[] memory amounts = new uint256[](3);

        amounts[0] = _SHIP_AMOUNT;
        amounts[1] = _SHIP_AMOUNT;
        amounts[2] = _SHIP_AMOUNT;

        allo().allocate(poolId, abi.encode(_shipAnchor, amounts, _GAME_AMOUNT));
        allo().distribute(poolId, _shipAnchor, abi.encode(block.timestamp, block.timestamp + _3_MONTHS));
        gameManager().startGame();
        vm.stopPrank();
    }

    function __generateShipData() internal {
        for (uint32 i = 0; i < 3;) {
            ShipInitData memory shipInitData = ShipInitData(
                true,
                true,
                true,
                "GrantShipStrategy",
                Metadata(1, string.concat("ipfs://grant-ships/ship.json/", vm.toString(i))),
                team(i).wearer,
                shipOperator(i).id,
                facilitator().id
            );

            _shipSetupData.push(shipInitData);
            unchecked {
                i++;
            }
        }
    }

    function __initGameManager() internal {
        _gameManager = new GameManagerStrategy(address(allo()), gameManagerStrategyId);
    }

    function __initFactory() internal {
        _shipImpl = new GrantShipStrategy(address(allo()), "GrantShipStrategy");
        _shipFactory = new GrantShipFactory(address(_shipImpl));
    }

    function __initGameManagerPool() internal {
        vm.startPrank(pool_admin());
        // Note: Can't test emitter because I don't have access to gameManagerPoolId before init
        gameManagerPoolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_gameManager),
            abi.encode(facilitator().id, address(hats()), pool_admin()),
            address(ARB()),
            0,
            Metadata(IPFS, "ipfs://grant-ships/about.json"),
            // pool manager/game facilitator role will be mediated through Hats Protocol
            // pool_admin address will be the game_facilitator multisig
            // using pool_admin as a single address for both roles
            noManagers
        );
        vm.stopPrank();

        assertEq(gameManager().gameFacilitatorHatId(), facilitator().id);
        assertEq(gameManager().rootAccount(), pool_admin());
        assertEq(gameManager().token(), address(ARB()));
    }
}
