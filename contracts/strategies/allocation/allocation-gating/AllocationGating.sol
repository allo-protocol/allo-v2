// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseStrategy} from "../../BaseStrategy.sol";

abstract contract AllocationGating is BaseStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error NOT_IMPLEMENTED();
    error NOT_ELIGIBLE();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    struct PayoutSummary {
        address recipient;
        uint256 amount;
        uint256 percentage;
    }

    bool public payoutReady;

    ///@notice recipientId -> PayoutSummary
    mapping(address => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Allocated(bytes data, address indexed allocator);
    event PayoutReady();

    constructor(address _allo) public BaseStrategy(_allo) {}

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice not implemented
    function registerRecipients(bytes memory, address) external payable override returns (address) {
        revert NOT_IMPLEMENTED();
    }

    /// @notice Checks if msg.sender is eligible for allocation
    function getRecipientStatus(address) external view override returns (RecipientStatus) {
        if (_isEligibleForAllocation(msg.sender)) {
            return RecipientStatus.Accepted;
        }
        return RecipientStatus.Rejected;
    }

    /// @notice Set allocations by pool manager
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function allocate(bytes memory _data, address _sender) external payable override onlyAllo {
        if (!allo.isPoolManager(poolId, _sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }

        // decode data
        PayoutSummary[] memory allocations = abi.decode(_data, (PayoutSummary[]));

        uint256 allocationsLength = allocations.length;
        for (uint256 i = 0; i < allocationsLength;) {
            PayoutSummary memory allocation = allocations[i];

            if (!_isEligibleForAllocation(allocation.payoutAddress)) {
                revert NOT_ELIGIBLE();
            }

            payoutSummaries[allocation.payoutAddress] = allocation;

            unchecked {
                i++;
            }
        }

        emit Allocated(_data, _sender);
    }

    /// @notice Get the payout summary for recipients
    /// @param _recipientId Array of recipient ids
    function getPayout(address[] memory _recipientId, bytes memory)
        external
        view
        returns (PayoutSummary[] memory summaries)
    {
        uint256 recipientIdLength = _recipientId.length;
        summaries = new PayoutSummary[](recipientIdLength);

        for (uint256 i = 0; i < recipientIdLength;) {
            summaries[i] = payoutSummaries[_recipientId[i]];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set ready for payout
    function setReadyForPayout() external onlyPoolManager {
        payoutReady = true;
        emit PayoutReady();
    }

    /// @notice Check if the strategy is ready to payout
    function readyToPayout(bytes memory) external view returns (bool) {
        return payoutReady;
    }

    /// @notice Checks if recipient is eligible for allocation
    /// @param _recipient Address of the recipient
    function _isEligibleForAllocation(address _recipient) internal view virtual returns (bool) {}
}
