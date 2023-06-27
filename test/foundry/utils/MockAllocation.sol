// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IAllocationStrategy.sol";

contract MockAllocation is IAllocationStrategy {
    function getOwnerIdentity() external view returns (string memory) {
        // Todo:
    }

    // decode the _data into what's relevant for this strategy
    // update whatever is needed to store the applicant
    // @todo return arbitrary data to pass back? think more about this
    function applyToPool(bytes memory _data, address sender) external payable returns (bytes memory) {
        // Todo:
    }

    // return whether application is pending, accepted, or rejected
    // strategies will need to add their own logic to translate to these categories if they use different ones
    function getApplicationStatus(uint256 applicationId) external view returns (ApplicationStatus) {
        // Todo:
    }

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here
    // we'll also use beforeAllocation() and afterAllocation() hooks so users can override when customizing
    // return the number of votes cast
    function allocate(bytes memory _data, address sender) external payable returns (uint256) {
        // Todo:
    }

    // can only be called by allo address
    // return list of addresses combined with WAD percentages to pay out
    // @todo there will be other return formats
    // define formats for returns here so we can explicitly say which distribution strategies are compatible
    function generatePayouts() external payable returns (bytes memory) {
        // Todo:
    }
}
