// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy contracts
import {GrantShipStrategy} from "../../../contracts/strategies/_poc/grant-ships/GrantShipStrategy.sol";
// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

contract GrantShiptStrategyTest is Test, RegistrySetupFull, AlloSetup, Native, EventSetup, Errors {
    Metadata public shipMetadata;

    GrantShipStrategy public strategyImplementation;
    GrantShipStrategy public strategy;

    uint256 poolId;
    address token = NATIVE;

    address[] poolAdminAsManager = new address[](1);

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategyImplementation = new GrantShipStrategy(address(allo()), "GrantShipStrategy");

        vm.startPrank(allo_owner());

        allo().addToCloneableStrategies(address(strategyImplementation));
        allo().updatePercentFee(0);

        vm.stopPrank();

        address payable strategyAddress;
        (poolId, strategyAddress) = _createPool(
            true, // registryGating
            true, // metadataRequired
            true // grantAmountRequired
        );

        strategy = GrantShipStrategy(strategyAddress);
    }

    // ================= Helper ===================

    function _createPool(bool _registryGating, bool _metadataRequired, bool _grantAmountRequired)
        internal
        returns (uint256 newPoolId, address payable strategyClone)
    {
        vm.deal(pool_admin(), 30e18);
        poolAdminAsManager[0] = pool_admin();
        console.log("pool_admin: %s", pool_admin());

        vm.startPrank(pool_admin());

        newPoolId = allo().createPool{value: 30e18}(
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

    function test() public {}
}
