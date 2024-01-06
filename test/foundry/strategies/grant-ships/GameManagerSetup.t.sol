// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Internal Libraries
import {Accounts} from "../../shared/Accounts.sol";
import {HatsSetupLive} from "./HatsSetup.sol";

contract GameManagerSetup is Test, HatsSetupLive {}
