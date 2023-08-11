// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*
This is the module used to manage the recipients of a pool. It can be used to register (add) recipients to a pool,
with functions for checking status within a given pool.

Examples include:

    - Recipient must apply, approval is given manually
    - Recipient must apply, approval is given programmatically based on requirements
    - Recipient must apply, but application is gated on a verifier and approval given manually
    - Recipient is listed in another registry, automatically eligible 

*/

/// @title Recipient Module - Manages the recipients of a pool
/// @notice This module is used to manage the recipients of a pool
/// @author allo-team
contract Recipient {
    constructor() {}

    // NOTE:
    /// @notice Adds a recipient
    /// @param _recipient The address of the recipient to add
    function addRecipient(address _recipient) external {}

    // NOTE:
    /// @notice Removes a recipient
    /// @param _recipient The address of the recipient to remove
    function removeRecipient(address _recipient) external {}
}
