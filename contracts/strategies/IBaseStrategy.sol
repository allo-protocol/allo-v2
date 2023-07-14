// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "./IStrategy.sol";
import {Payouts} from "../core/libraries/Payouts.sol";

interface IBaseStrategy is IStrategy {
    function getPayout(address[] memory _recipientIds, bytes memory _data) external returns (Payouts.PayoutSummary[] memory);
    function readyToPayout(address recipeint) external view returns (bool);
}
