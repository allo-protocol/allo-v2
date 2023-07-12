// SPDX-License-Identifier:  AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";
import {WinnerTakeAll} from "../modules/allocation/WinnerTakeAll.sol";
import {OpenVoting} from "../modules/voter/OpenVoting.sol";
import {OpenSelfRegistration} from "../modules/recipient/OpenSelfRegistration.sol";
import {OneVotePerAddress} from "../modules/voting/OneVotePerAddress.sol";
import {OpenERC20Distribution} from "../modules/distribution/OpenERC20Distribution.sol";

contract WinnerTakesAllLinearVotes is
    BaseStrategy,
    WinnerTakeAll,
    OpenVoting,
    OpenSelfRegistration,
    OneVotePerAddress,
    OpenERC20Distribution
{}
