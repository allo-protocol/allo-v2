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
import {RegistrySetupFullLive} from "../../shared/RegistrySetup.sol";
import {HatsSetupLive} from "./HatsSetup.sol";
import {EventSetup} from "../../shared/EventSetup.sol";

contract GrantShiptStrategyTest is Test, RegistrySetupFullLive, AlloSetup, HatsSetupLive, Native, EventSetup, Errors {
    Metadata public shipMetadata;

    GrantShipStrategy public shipStrategyImplementation;
    GrantShipStrategy public shipStrategy;

    GameManagerStrategy public gameManagerImplementation;

    uint256 poolId;
    address token = NATIVE;

    address[] poolAdminAsManager = new address[](1);

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

        address payable strategyAddress;
        (poolId, strategyAddress) = _createGameManager(facilitator().id, address(arbToken), address(hats()));
        // _createPool(
        //     true, // registryGating
        //     true, // metadataRequired
        //     true // grantAmountRequired
        // );
        //  shipStrategy = GrantShipStrategy(strategyAddress);
    }

    // ================= Helpers ===================

    function __setup_strategies() internal {
        shipStrategyImplementation = new GrantShipStrategy(address(allo()), "GrantShipStrategy");
        gameManagerImplementation = new GameManagerStrategy(address(allo()), "GameManagerStrategy");
    }

    function _createPool(bool _registryGating, bool _metadataRequired, bool _grantAmountRequired)
        internal
        returns (uint256 newPoolId, address payable strategyClone)
    {
        vm.deal(pool_admin(), 30e18);
        poolAdminAsManager[0] = pool_admin();

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
            poolAdminAsManager
        );

        vm.stopPrank();

        strategyClone = payable(address(allo().getPool(newPoolId).strategy));
    }

    function _createGameManager(uint256 _gameFacilitatorId, address _token, address _hatsAddress)
        internal
        returns (uint256 newPoolId, address payable strategyClone)
    {
        vm.prank(pool_admin());
        arbToken.approve(address(allo()), 30_000e18);

        vm.startPrank(pool_admin());

        bytes[] memory _shipData = new bytes[](1);

        _shipData[0] = abi.encode(1234);

        poolAdminAsManager[0] = pool_admin();

        newPoolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(gameManagerImplementation),
            abi.encode(abi.encode(_gameFacilitatorId, _token, _hatsAddress), _shipData),
            _token,
            30_000e18,
            Metadata(1, "game-controller-data"),
            poolAdminAsManager
        );

        // strategyClone = payable(address(allo().getPool(newPoolId).strategy));
    }

    function testtest() public {
        console.log("poolId: %s", poolId);
    }
}
