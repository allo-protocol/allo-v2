// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "./IStrategy.sol";

interface IBaseStrategy is IStrategy {
    struct PayoutSummary {
        address recipient;
        uint256 amount;
        uint256 percentage;
    }

    function getPayout(address[] memory _recipientIds, bytes memory _data) external returns (PayoutSummary[] memory);
    function readyToPayout(address recipeint) external view returns (bool);
}
