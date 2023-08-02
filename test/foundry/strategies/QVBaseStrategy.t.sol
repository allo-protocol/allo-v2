// SPDX-License Identifier: MIT
pragma solidity 0.8.19;

// Internal Libraries
import {Native} from "../../../contracts/core/libraries/Native.sol";

// Test Helpers
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {StrategySetup} from "../shared/StrategySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {EventSetup} from "../shared/EventSetup.sol";

// NOTE: Not sure what to test here yet... this is an abstract contract and cover 99% of the code in
// the strategy tests. Leaving this here for now in case we need to test something specific to this.
contract QVBaseStrategyTest is StrategySetup, RegistrySetupFull, AlloSetup, EventSetup, Native {}
