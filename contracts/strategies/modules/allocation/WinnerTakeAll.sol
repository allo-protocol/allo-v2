// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStrategy } from "../../IStrategy.sol";
import { IAllocationModule } from "./IAllocationModule.sol";

contract WinnerTakeAll is IAllocationModule, IStrategy {
    function initializeAllocationModule(bytes memory _data) external {}

    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[]) {
        require(recipientIds.length == 0, "pass empty rec, will use all");
        address[] memory recipients = allRecipients();
        uint[] memory results = getResults(recipients);
        require(recipients.length == results.length);

        uint max;
        uint winner;
        for (uint i = 0; i < results.length; i++) {
            if (results[i] > max) {
                max = results[i];
                winner = recipients[i];
            }
        }

        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        for (uint i = 0; i < recipientIds.length; i++) {
            if (recipients[i] == winner) {
                payouts[0] = PayoutSummary(recipients[i], address(this).balance);
            }
        }
        return payouts;
    }
}
