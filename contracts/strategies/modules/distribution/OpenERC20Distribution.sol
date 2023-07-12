// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "../../IStrategy.sol";
import {IDistributionModule} from "./IDistributionModule.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract OpenERC20Distribution is IDistributionModule, IStrategy {
    ERC20 token;
    mapping (address => uint) public claimed;

    function initializeDistributionModule(bytes memory _data) external {
        token = ERC20(abi.decode(_data, (address)));
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {
        PayoutSummary[] memory payouts = getPayouts(_recipientIds, _data);
        for (uint i = 0; i < payouts.length; i++) {
            address recipient = payouts[i].recipientId;
            uint amountOwed = payouts[i].amount - claimed[recipient];
            claimed[recipient] = payouts[i].amount;
            token.transfer(recipient, amountOwed);
        }
    }
}
