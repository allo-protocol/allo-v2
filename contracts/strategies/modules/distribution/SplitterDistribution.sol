// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IDistributionModule} from "./IDistributionModule.sol";
import {Transfer} from "../../../core/libraries/Transfer.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract SplitterDistributionStrategy is IDistributionModule, IStrategy {
    /// @notice Custom errors
    error PAYOUT_NOT_READY();
    error PAYOUT_FINALIZED();
    error ALREADY_DISTRIBUTED();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================
    ERC20 token;

    /// Recipient.id -> amount paid
    mapping(address => uint256) public paidAmounts;

    /// ======================
    /// ======= Events =======
    /// ======================

    event PayoutsDistributed(address[] recipientIds, PayoutSummary[] payoutSummary, address sender);

    function initializeDistributionModule(bytes memory _data) external {
        token = ERC20(abi.decode(_data, (address)));
    }

    /// @notice Distribute the payouts to the recipients
    /// @param _recipientIds The recipientIds to distribute to
    /// @param _data encoded bytes passed to the allocation strategy
    /// @param _sender The sender of the payouts
    function distribute(address[] memory _recipientIds, bytes calldata _data, address _sender)
        external
        onlyAllo
        nonReentrant
    {
        IAllocationStrategy allocationStrategy = IAllocationStrategy(allo.getAllocationStrategy(poolId));

        if (!allocationStrategy.readyToPayout("0x")) {
            revert PAYOUT_NOT_READY();
        }

        PayoutSummary[] memory payouts = allocationStrategy.getPayout(_recipientIds, _data);

        uint256 recipientIdsLength = _recipientIds.length;

        for (uint256 i = 0; i < recipientIdsLength;) {
            address recipientId = _recipientIds[i];

            if (paidAmounts[recipientId] > 0) {
                revert ALREADY_DISTRIBUTED();
            }

            uint256 amountToTransfer = (amount * payouts[i].percentage) / 1e18;

            paidAmounts[recipientId] = amountToTransfer;

            _transferAmount(token, payouts[i].payoutAddress, amountToTransfer);
            unchecked {
                i++;
            }
        }

        emit PayoutsDistributed(_recipientIds, payouts, _sender);
    }

    /// @notice invoked via allo.fundPool to update pool's amount
    /// @param _amount amount by which pool is increased
    function poolFunded(uint256 _amount) public override onlyAllo {
        if (IAllocationStrategy(allo.getAllocationStrategy(poolId)).readyToPayout("0x")) {
            revert PAYOUT_FINALIZED();
        }
        super.poolFunded(_amount);
    }
}
