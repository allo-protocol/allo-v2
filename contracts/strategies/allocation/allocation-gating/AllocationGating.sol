// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseAllocationStrategy} from "../BaseAllocationStrategy.sol";

abstract contract AllocationGating is BaseAllocationStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error NOT_IMPLEMENTED();
    error NOT_ELIGIBLE();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    bool public payoutReady;

    ///@notice recipentId -> PayoutSummary
    mapping(uint256 => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Allocated(bytes data, address indexed allocator);

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice not implemented
    function applyToPool(bytes memory, address) external payable override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @notice Checks if msg.sender is eligible for allocation
    function getApplicationStatus(uint256) external view override returns (ApplicationStatus) {
        if (_isEligibleForAllocation(msg.sender)) {
            return ApplicationStatus.Accepted;
        }
        return ApplicationStatus.Rejected;
    }

    /// @notice Set allocations by pool manager
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function allocate(bytes memory _data, address _sender) external payable override onlyAllo {
        if (!allo.isPoolManager(poolId, _sender)) {
            revert UNAUTHORIZED();
        }

        // decode data
        PayoutSummary[] memory allocations = abi.decode(_data, (PayoutSummary[]));

        uint256 allocationsLength = allocations.length;
        for (uint256 i = 0; i < allocationsLength;) {
            if (!_isEligibleForAllocation(allocations[i].recipient)) {
                revert NOT_ELIGIBLE();
            }

            // TODO: Fix this logic
            payoutSummaries[i] = allocations[i];

            unchecked {
                i++;
            }
        }

        emit Allocated(_data, _sender);
    }

    /// @notice Get the payout summary for applications
    /// @param _recipentId Array of application ids
    function getPayout(uint256[] memory _recipentId, bytes memory)
        external
        view
        override
        returns (PayoutSummary[] memory summaries)
    {
        uint256 recipentIdLength = _recipentId.length;
        summaries = new PayoutSummary[](recipentIdLength);

        for (uint256 i = 0; i < recipentIdLength;) {
            summaries[i] = payoutSummaries[_recipentId[i]];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if the strategy is ready to payout
    function readyToPayout(bytes memory) external view override returns (bool) {
        return payoutReady;
    }

    /// @notice Checks if recipient is eligible for allocation
    /// @param _recipient Address of the recipient
    function _isEligibleForAllocation(address _recipient) internal view virtual returns (bool) {}
}
