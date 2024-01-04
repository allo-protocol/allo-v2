// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../../contracts/core/interfaces/IStrategy.sol";

// Strategy contracts
import {GrantShipStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";

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

    GrantShipStrategy public strategyImplementation;
    GrantShipStrategy public strategy;

    uint256 poolId;
    address token = NATIVE;

    address[] poolAdminAsManager = new address[](1);

    function setUp() public {
        vm.createSelectFork({blockNumber: 166_807_779, urlOrAlias: "arbitrumOne"});
        __RegistrySetupFullLive();
        __AlloSetupLive();
        __HatsSetupLive(pool_admin());
        __setup_strategy();

        address payable strategyAddress;
        (poolId, strategyAddress) = _createPool(
            true, // registryGating
            true, // metadataRequired
            true // grantAmountRequired
        );

        strategy = GrantShipStrategy(strategyAddress);
    }

    // ================= Helpers ===================

    function __setup_strategy() internal {
        strategyImplementation = new GrantShipStrategy(address(allo()), "GrantShipStrategy");
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
            address(strategyImplementation),
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

    function testtest() public {
        console.log("poolId: %s", poolId);
    }
}
