// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Transfer} from "../../../core/libraries/Transfer.sol";
import {Payout} from "../../Strategy.sol";

abstract contract SingleTransfer is Transfer {
    /// ======================
    /// ======= Events =======
    /// ======================

    event Distributed(address recipientIds, Payout payoutSummary, address sender);

    /// ====================================
    /// ==== Internal Functions =====
    /// ====================================

    function _distribute(address _token, address _recipientId, Payout payout, address _sender) internal {
        _transferAmount(_token, payout.payoutAddress, payout.amount);
        emit Distributed(_recipientId, payout, _sender);
    }
}
