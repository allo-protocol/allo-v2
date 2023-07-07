// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IStrategy.sol";

interface IAllocationStrategy is IStrategy {
    enum ApplicationStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    // initialize the strategy with the poolId and allo address
    // set initialized to true and ensure it can't be called again
    // check if identityId passed, is same as the identityId set during deployment
    // if identityId is not set during deployment, then set it (for clones)
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) external;

    // decode the _data into what's relevant for this strategy
    // update whatever is needed to store the applicant
    // return the applicationId
    function addRecipient(bytes memory _data, address sender) external payable returns (uint256);

    // return whether application is pending, accepted, or rejected
    // strategies will need to add their own logic to translate to these categories if they use different ones
    function getApplicationStatus(uint256 _applicationId) external view returns (ApplicationStatus);

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here
    // we'll also use beforeAllocation() and afterAllocation() hooks so users can override when customizing
    // return the number of votes cast
    function allocate(bytes memory _data, address _sender) external payable;

    // generate the payouts for the strategy
    function getPayout(uint256[] memory _applicationId, bytes memory _data)
        external
        view
        returns (PayoutSummary[] memory summaries);

    // signal that pool is ready for distribution
    function readyToPayout(bytes memory _data) external view returns (bool);

    // many owners will probably want a way to add custom application approval logic
    // but all of that will be in specific implementations, not requried interface
}
