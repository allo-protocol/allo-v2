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

    /// @notice Struct to hold details of an application
    struct Application {
        // TODO:Add
        address recipent;
    }

    /// @notice Simple registry to auto approve applications
    SimpleProjectRegistry public simpleProjectRegistry;

    /// @notice recipentId - Status
    mapping(uint256 => ApplicationStatus) public applicationStatus;

    /// @notice recipentId -> Application
    mapping(uint256 => Application) public applications;

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
    // function applyToPool(bytes memory _data, address) external payable override returns (uint256) {
    //     address projectId = abi.decode(_data, (address));
    //     if (!simpleProjectRegistry.projects[projectId]) {
    //         // TODO: Add to pool
    //     }
    //     revert NOT_ELIGIBLE();
    // }

    // /// @notice Returns the status of the application
    // /// @param _recipentId The recipentId of the application
    // function getApplicationStatus(uint256 _recipentId) external view override returns (ApplicationStatus) {
    //     return applicationStatus[_recipentId];
    // }

    // /// @notice Set allocations by pool manager
    // /// @param _data The data to be decoded
    // /// @param _sender The sender of the allocation
    // function allocate(bytes memory _data, address _sender) external payable override onlyAllo {

    //     // decode data
    //     PayoutSummary[] memory allocations = abi.decode(_data, (PayoutSummary[]));

    //     uint256 allocationsLength = allocations.length;
    //     for (uint256 i = 0; i < allocationsLength;) {

    //         // TODO: check if application is approved

    //         // TODO: Fix this logic
    //         payoutSummaries[i] = allocations[i];

    //         unchecked {
    //             i++;
    //         }
    //     }

    //     emit Allocated(_data, _sender);
    // }

    // /// @notice Get the payout summary for applications
    // /// @param _recipentId Array of application ids
    // function getPayout(uint256[] memory _recipentId, bytes memory)
    //     external
    //     view
    //     override
    //     returns (PayoutSummary[] memory summaries)
    // {
    //     uint256 recipentIdLength = _recipentId.length;
    //     summaries = new PayoutSummary[](recipentIdLength);

    //     for (uint256 i = 0; i < recipentIdLength;) {
    //         summaries[i] = payoutSummaries[_recipentId[i]];
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
