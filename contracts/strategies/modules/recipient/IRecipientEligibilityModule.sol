// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy }  from "../../IStrategy.sol";

interface IRecipientEligibilityModule {
    enum RecipientStatus { None, Pending, Accepted, Rejected }
    function initializeRecipientEligibilityModule(bytes memory _data) external;
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    function allRecipients() public view returns (address[] memory);
}
