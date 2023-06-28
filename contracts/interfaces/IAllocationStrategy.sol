// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAllocationStrategy {
    /**
     * STORAGE (with public getters)
     *     uint256 poolId;
     *     address allo;
     */

    enum ApplicationStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    // return whether this strategy is cloneable or not
    function isCloneable() external pure returns (bool);

    // call to allo() to get identity for pool, then to registry() to get metadata
    function getOwnerIdentity() external view returns (string memory);

    // decode the _data into what's relevant for this strategy
    // update whatever is needed to store the applicant
    // return the applicationId
    function applyToPool(bytes memory _data, address sender) external payable returns (uint256);

    // return whether application is pending, accepted, or rejected
    // strategies will need to add their own logic to translate to these categories if they use different ones
    function getApplicationStatus(uint256 applicationId) external view returns (ApplicationStatus);

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here
    // we'll also use beforeAllocation() and afterAllocation() hooks so users can override when customizing
    // return the number of votes cast
    function allocate(bytes memory _data, address sender) external payable returns (uint256);

    // can only be called by allo address
    // return list of addresses combined with WAD percentages to pay out
    // @todo there will be other return formats
    // define formats for returns here so we can explicitly say which distribution strategies are compatible
    function generatePayouts() external payable returns (bytes memory);

    // many owners will probably want a way to add custom application approval logic
    // but all of that will be in specific implementations, not requried interface
}
