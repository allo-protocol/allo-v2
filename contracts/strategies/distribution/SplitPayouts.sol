// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract SplitPayoutsStrategy {
    struct Payout {
        address to;
        uint256 amount;
    }

    Payout[] public payouts;

    constructor() {}

    function activateDistribution(bytes memory _data) external {
        // todo: decode _data into a struct with a list of addresses and amounts
    }

    function distribute(bytes memory _data) external {
        // todo:
    }
}
