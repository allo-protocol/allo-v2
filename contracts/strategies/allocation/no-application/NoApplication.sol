// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseAllocationStrategy} from "../BaseAllocationStrategy.sol";
import {IAllocationStrategy} from "../../../interfaces/IAllocationStrategy.sol";

/**
 * This is used for strategies that do not require an application, such as a token balance strategy.
 */

/// @title NoApplication
/// @notice A strategy that does not require an application
/// @dev This strategy is used for strategies that do not require an application
/// @author @thelostone-mc, allo-team
abstract contract NoApplication is BaseAllocationStrategy {
    /// =======================
    /// ==== Custom Errors ====
    /// =======================

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

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice NOT_IMPLEMENTED
    function registerRecipient(bytes memory, address) external payable override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @notice NOT_IMPLEMENTED
    function getApplicationStatus(uint256) external pure override returns (ApplicationStatus) {
        revert NOT_IMPLEMENTED();
    }

    /// @notice Gets the payout summary for the given application ids
    /// @param _applicationId The application ids to get the payout summary for
    /// @param _data The data to be decoded
    function getPayout(uint256[] memory _applicationId, bytes memory _data)
        external
        view
        returns (PayoutSummary[] memory summaries)
    {
        _data;
        uint256 applicationIdLength = _applicationId.length;
        summaries = new PayoutSummary[](applicationIdLength);

        for (uint256 i = 0; i < applicationIdLength;) {
            summaries[i] = payoutSummaries[_applicationId[i]];
            unchecked {
                i++;
            }
        }

        return summaries;
    }

    /// @notice Allocates the funds to the recipients
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
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
    // NOTE: how does this get set?
    /// @notice Checks if the pool is ready to payout
    /// @param _data The data to be decoded
    function readyToPayout(bytes memory _data) external view override returns (bool) {
        _data;

        return payoutReady;
    }

    /// ==================================
    /// === Internal/Private Functions ===
    /// ==================================

    /// @notice Checks if the recipient is eligible for allocation
    /// @param _recipient The recipient to check
    function _isEligibleForAllocation(address _recipient) internal view virtual returns (bool) {}
}
