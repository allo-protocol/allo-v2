// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract Payouts {
    struct PayoutSummary {
        address recipient;
        uint256 amount;
        uint256 percentage;
    }
}
