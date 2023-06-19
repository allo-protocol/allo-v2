// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAllocationStrategy {
    /**
        STORAGE (with public getters)
        uint256 poolId;
        address allo;
        uint64 applicationStart;
        uint64 applicationEnd;
        uint64 votingStart;
        uint64 votingEnd;
    */

    // call to allo() and query pools[poolId].owner
    function owner() external view returns (address);

    // decode the _data into what's relevant for this strategy
    // update whatever is needed to store the applicant
    // @todo return arbitrary data to pass back? think more about this
    function applyToPool(bytes memory _data) external payable returns (bytes memory);

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here
    // we'll also use beforeAllocation() and afterAllocation() hooks so users can override when customizing
    // return the number of votes cast
    function allocate(bytes memory _data) external payable returns (uint);

    // can only be called by allo address
    // return list of addresses combined with WAD percentages to pay out
    // @todo there will be other return formats
    // define formats for returns here so we can explicitly say which distribution strategies are compatible
    function generatePayouts() external payable returns (bytes memory);
}