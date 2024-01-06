// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";

// Strategy contracts
import {GrantShipStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";

// Internal libraries
import {Errors} from "../../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../../contracts/core/libraries/Native.sol";

// Test libraries
import {AlloSetup} from "../../shared/AlloSetup.sol";
import {RegistrySetupFullLive} from "../../shared/RegistrySetup.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {EventSetup} from "../../shared/EventSetup.sol";

contract GrantShiptStrategyTest is Test, RegistrySetupFullLive, AlloSetup, HatsSetupLive, Native, EventSetup, Errors {
    Metadata public shipMetadata;

    GrantShipStrategy public shipStrategyImplementation;
    GrantShipStrategy public shipStrategy;

    GameManagerStrategy public gameManager;
    string public gameManagerStrategyId = "GameManagerStrategy";

    uint256 poolId;
    address token = NATIVE;

    address[] noManagers = new address[](0);

    IERC20 arbToken = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    // Binance Hot Wallet
    // Use for testing on Arbitrum state
    address arbWhale = 0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D;

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __setup_strategies();

        vm.prank(arbWhale);
        arbToken.transfer(pool_admin(), 90_000e18);

        (poolId) = __createGameManager(facilitator().id, address(arbToken), address(hats()));
        // _createPool(
        //     true, // registryGating
        //     true, // metadataRequired
        //     true // grantAmountRequired
        // );
        //  shipStrategy = GrantShipStrategy(strategyAddress);
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

        vm.startPrank(pool_admin());

        bytes[] memory _shipData = new bytes[](3);

        console.log("ship(0).wearer", ship(0).wearer);

        _shipData[0] = abi.encode("Grant Ship 1", Metadata(1, "grant-ship-1-data"), ship(0).wearer);
        _shipData[1] = abi.encode("Grant Ship 2", Metadata(1, "grant-ship-2-data"), ship(1).wearer);
        _shipData[2] = abi.encode("Grant Ship 3", Metadata(1, "grant-ship-2-data"), ship(2).wearer);
        // _shipData[2] = abi.encode("Grant Ship 3", Metadata(1, "grant-ship-3-data"), ship(2).wearer);

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

    function __setup_strategies() internal {
        shipStrategyImplementation = new GrantShipStrategy(address(allo()), "GrantShipStrategy");
    }

    function _createPool(bool _registryGating, bool _metadataRequired, bool _grantAmountRequired)
        internal
        returns (uint256 newPoolId, address payable strategyClone)
    {
        vm.deal(pool_admin(), 30e18);

        vm.startPrank(pool_admin());

        newPoolId = allo().createPoolWithCustomStrategy{value: 30e18}(
            poolProfile_id(),
            address(shipStrategyImplementation),
            abi.encode(_registryGating, _metadataRequired, _grantAmountRequired),
            token,
            30e18,
            Metadata(1, "grant-ship-data"),
            // pool manager/game facilitator role will be mediated through Hats Protocol
            // pool_admin address will be the game_facilitator multisig
            // using pool_admin as a single address for both roles
            noManagers
        );

        vm.stopPrank();

        strategyClone = payable(address(allo().getPool(newPoolId).strategy));
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
