// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {SimpleProjectRegistry} from "./mock/SimpleProjectRegistry.sol";

// Intefaces
import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

contract AltRegistryStrategy is BaseStrategy, ReentrancyGuard {

}

