// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseAllocationStrategy} from "../BaseAllocationStrategy.sol";
import {IAllocationStrategy} from "../../../interfaces/IAllocationStrategy.sol";

abstract contract NoApplication is IAllocationStrategy, BaseAllocationStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error NOT_IMPLEMENTED();
    error NOT_ELIGIBLE();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    bool public payoutReady;

    ///@notice applicationId -> PayoutSummary
    mapping(uint256 => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Allocated(bytes data, address indexed allocator);

    function applyToPool(bytes memory, address) external payable override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    function getApplicationStatus(uint256) external pure override returns (ApplicationStatus) {
        revert NOT_IMPLEMENTED();
    }

    function getPayout(uint256[] memory _applicationId, bytes memory)
        external
        view
        returns (PayoutSummary[] memory summaries)
    {
        uint256 applicationIdLength = _applicationId.length;
        summaries = new PayoutSummary[](applicationIdLength);

        for (uint256 i = 0; i < applicationIdLength;) {
            summaries[i] = payoutSummaries[_applicationId[i]];
            unchecked {
                i++;
            }
        }
    }

    function allocate(bytes memory _data, address _sender) external payable override onlyPoolManager {
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

    // signal that pool is ready for distribution
    function readyToPayout(bytes memory) external view override returns (bool) {
        return payoutReady;
    }

    function _isEligibleForAllocation(address _sender) internal view returns (bool) {}
}
