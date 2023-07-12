// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "../../IStrategy.sol";

interface IRecipientEligibilityModule {
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    function initializeRecipientEligibilityModule(bytes memory _data) external;
    // used to set any initial variables, such as token address if there is token gating

    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected

    function allRecipients() public view returns (address[] memory);
    // return an array of all recipients, needed for any kind of "winner take all" thing
    // in those cases, we'll ignroe the passed `recipientIds` passed to distribute and just use this
}
