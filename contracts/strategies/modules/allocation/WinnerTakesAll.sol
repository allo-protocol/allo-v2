// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "../../IStrategy.sol";
import {IAllocationModule} from "./IAllocationModule.sol";

contract WinnerTakesAll is IAllocationModule, IStrategy {
    function initializeAllocationModule(bytes memory _data) external {}

    function getPayouts(address[] memory recipientIds, bytes memory _data) public view returns (PayoutSummary[]) {
        require(recipientIds.length == 0, "pass empty rec, will use all");
        address[] memory recipients = allRecipients();
        uint256[] memory results = getResults(recipients);
        require(recipients.length == results.length);

        uint256 max;
        uint256 winner;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i] > max) {
                max = results[i];
                winner = recipients[i];
            }
        }

        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        for (uint256 i = 0; i < recipientIds.length; i++) {
            if (recipients[i] == winner) {
                payouts[0] = PayoutSummary(recipients[i], address(this).balance);
            }
        }
        return payouts;
    }
}
