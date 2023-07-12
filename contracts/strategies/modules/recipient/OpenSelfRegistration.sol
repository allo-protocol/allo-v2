// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { IRecipientEligibilityModule } from "./IRecipientEligibilityModule.sol";

contract OpenSelfRegistration is IRecipientEligibilityModule {
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    address[] recipients;
    mapping(address => bool) isRecipient;

    function initializeRecipientEligibilityModule(bytes memory _data) external {}

    function registerRecipients(bytes memory _data, address _sender) external payable {
        require(!isRecipient[_sender], "already registered");
        recipients.push(_sender);
        isRecipient[_sender] = true;
    }

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        } else {
            return RecipientStatus.None;
        }
    }

    function allRecipients() public view returns (address[] memory) {
        return recipients;
    }
}
