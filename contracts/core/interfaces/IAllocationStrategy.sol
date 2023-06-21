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

    enum ApplicationStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    // call to allo() and query pools[poolId].owner
    function owner() external view returns (address);

    // decode the _data into what's relevant for this strategy
    // update whatever is needed to store the applicant
    // @todo return arbitrary data to pass back? think more about this
    function applyToPool(
        bytes memory _data,
        address sender
    ) external payable returns (bytes memory);

    // return whether application is pending, accepted, or rejected
    // strategies will need to add their own logic to translate to these categories if they use different ones
    // @todo should this be bytes memory or can we assume application is bytes32 / uint?
    function getApplicationStatus(
        bytes memory _data
    ) external view returns (ApplicationStatus);

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here
    // we'll also use beforeAllocation() and afterAllocation() hooks so users can override when customizing
    // return the number of votes cast
    function allocate(
        bytes memory _data,
        address sender
    ) external payable returns (uint);

    // can only be called by allo address
    // return list of addresses combined with WAD percentages to pay out
    // @todo there will be other return formats
    // define formats for returns here so we can explicitly say which distribution strategies are compatible
    function generatePayouts() external payable returns (bytes memory);
}
