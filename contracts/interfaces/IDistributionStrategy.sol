// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IStrategy.sol";

interface IDistributionStrategy is IStrategy {
    // decode the _data into what's relevant to determine payouts
    // default will be a struct with a list of addresses and WAD percentages
    // turn "on" the abilty to distribute payouts
    function activateDistribution(bytes memory _inputData, bytes memory _allocStratData) external;

    // distribution a payout based on the strategy's needs
    // this could include merkle proofs, etc or just nothing
    function distribute(bytes memory _data, address sender) external;

    // many owners will probably want a way to update roots, pull out funds if not claimed, etc
    // but all of that will be in specific implementations, not requried interface
}
