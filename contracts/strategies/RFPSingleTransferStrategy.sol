// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Strategy} from "./Strategy.sol";
import {RFPAllocation} from "./modules/allocation/rfp/RFPAllocation.sol";
import {SingleTransfer} from "./modules/distribution/SingleTransfer.sol";

contract RFPSingleTransferStartegy is Strategy, RFPAllocation, SingleTransfer {
    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external {
        super.initialize(_identityId, _poolId, _data);

        _setStrategyIdentifier("RFPSingleTransferStrategy");
    }

    function distribute(address[] memory, bytes memory, address _sender) external {
        (,, address token,,,,) = allo.pools(poolId);

        Payout payouts = getRecipientPayouts(acceptedRecipientId, token);

        SingleTransfer._distribute(token, acceptedRecipientId, payouts[0], _sender);
    }
}
