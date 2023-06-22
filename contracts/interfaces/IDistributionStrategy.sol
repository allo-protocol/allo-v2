// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IDistributionStrategy {
    /**
        STORAGE (with public getters)
        uint256 poolId;
        address allo;
    */

    // call to allo() to get identity for pool, then to registry() to get metadata
    function getOwnerIdentity() external view returns (string memory);

    // decode the _data into what's relevant to determine payouts
    // default will be a struct with a list of addresses and WAD percentages
    // turn "on" the abilty to claim payouts
    function activateDistribution(bytes memory _inputData, bytes memory _allocStratData) external;

    // claim a payout based on the strategy's needs
    // this could include merkle proofs, etc or just nothing
    function distribute(bytes memory _data) external;

    // many owners will probably want a way to update roots, pull out funds if not claimed, etc
    // but all of that will be in specific implementations, not requried interface
}
