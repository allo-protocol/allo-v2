// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseAllocationStrategy} from "../BaseAllocationStrategy.sol";
import {SimpleProjectRegistry} from "./SimpleProjectRegistry.sol";

abstract contract AltRegistryGating is BaseAllocationStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error NOT_IMPLEMENTED();
    error NOT_ELIGIBLE();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        // TODO:Add
        address recipient;
    }

    /// @notice Simple registry to auto approve recipients
    SimpleProjectRegistry public simpleProjectRegistry;

    /// @notice recipientId - Status
    mapping(uint256 => RecipientStatus) public recipientStatus;

    /// @notice recipientId -> Recipient
    mapping(uint256 => Recipient) public recipients;

    bool public payoutReady;

    ///@notice recipientId -> PayoutSummary
    mapping(uint256 => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Allocated(bytes data, address indexed allocator);

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _allo Address of the Allo contract
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public override {
        super.initialize(_allo, _identityId, _poolId, _data);

        // decode data custom to this strategy
        (address _simpleProjectRegistry) = abi.decode(_data, (address));
        simpleProjectRegistry = SimpleProjectRegistry(_simpleProjectRegistry);
    }

    // /// @notice apply to the pool
    // function registerRecipients(bytes memory _data, address) external payable override returns (uint256) {
    //     address projectId = abi.decode(_data, (address));
    //     if (!simpleProjectRegistry.projects[projectId]) {
    //         // TODO: Add to pool
    //     }
    //     revert NOT_ELIGIBLE();
    // }

    // /// @notice Returns the status of the recipient
    // /// @param _recipientId The recipientId of the recipient
    // function getRecipientStatus(uint256 _recipientId) external view override returns (RecipientStatus) {
    //     return recipientStatus[_recipientId];
    // }

    // /// @notice Set allocations by pool manager
    // /// @param _data The data to be decoded
    // /// @param _sender The sender of the allocation
    // function allocate(bytes memory _data, address _sender) external payable override onlyAllo {

    //     // decode data
    //     PayoutSummary[] memory allocations = abi.decode(_data, (PayoutSummary[]));

    //     uint256 allocationsLength = allocations.length;
    //     for (uint256 i = 0; i < allocationsLength;) {

    //         // TODO: check if recipient is approved

    //         // TODO: Fix this logic
    //         payoutSummaries[i] = allocations[i];

    //         unchecked {
    //             i++;
    //         }
    //     }

    //     emit Allocated(_data, _sender);
    // }

    // /// @notice Get the payout summary for recipients
    // /// @param _recipientId Array of recipient ids
    // function getPayout(uint256[] memory _recipientId, bytes memory)
    //     external
    //     view
    //     override
    //     returns (PayoutSummary[] memory summaries)
    // {
    //     uint256 recipientIdLength = _recipientId.length;
    //     summaries = new PayoutSummary[](recipientIdLength);

    //     for (uint256 i = 0; i < recipientIdLength;) {
    //         summaries[i] = payoutSummaries[_recipientId[i]];
    //         unchecked {
    //             i++;
    //         }
    //     }
    // }

    /// @notice Check if the strategy is ready to payout
    function readyToPayout(bytes memory) external view override returns (bool) {
        return payoutReady;
    }
}
