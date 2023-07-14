// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Transfer} from "../../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {Payout} from "../../Strategy.sol";

abstract contract Splitter is ReentrancyGuard {
    /// @notice Custom errors
    error ALREADY_DISTRIBUTED();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    /// Recipient.id -> amount paid
    mapping(address => uint256) public paidAmounts;

    /// ======================
    /// ======= Events =======
    /// ======================

    event PayoutsDistributed(address[] recipientIds, PayoutSummary[] payoutSummary, address sender);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Distribute the payouts to the recipients
    /// @param _recipientIds The recipientIds to distribute to
    /// @param _data encoded bytes passed to the allocation strategy
    /// @param _sender The sender of the payouts
    function _distribute(address[] memory _recipientIds, bytes _data, address _sender) internal nonReentrant {
        PayoutSummary[] memory payouts = abi.decode(_data, (PayoutSummary[]));

        uint256 recipientIdsLength = _recipientIds.length;

        for (uint256 i = 0; i < recipientIdsLength;) {
            address recipientId = _recipientIds[i];

            if (paidAmounts[recipientId] > 0) {
                revert ALREADY_DISTRIBUTED();
            }

            uint256 amountToTransfer = payouts[i].amount;

            paidAmounts[recipientId] = amountToTransfer;

            _transferAmount(token, payouts[i].payoutAddress, amountToTransfer);
            unchecked {
                i++;
            }
        }

        emit PayoutsDistributed(_recipientIds, payouts, _sender);
    }
}
