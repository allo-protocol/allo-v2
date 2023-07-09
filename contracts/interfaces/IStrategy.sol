// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IStrategy {
    /**
     * STORAGE (with public getters)
     *     bool initialized;
     *     bytes32 identityId;
     *     uint256 poolId;
     *     address allo;
     */

    struct PayoutSummary {
        address payoutAddress;
        uint256 percentage;
    }
}
