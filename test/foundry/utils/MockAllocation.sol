// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IAllocationStrategy.sol";

contract MockAllocation is IAllocationStrategy {
    bytes32 public identityId;
    address public allo;
    uint256 public poolId;
    bool public initialized;

    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) external override {
        if (initialized) {
            revert();
        }
        initialized = true;

        // surpress compiler warnings:
        _allo;
        _identityId;
        _poolId;
        _data;
    }

    function applyToPool(bytes memory _data, address _sender) external payable override returns (uint256) {
        // surpress compiler warnings:
        _data;
        _sender;
        return 1;
    }

    function getApplicationStatus(uint256 _applicationId) external view override returns (ApplicationStatus) {
        // return ApplicationStatus.Applied;
    }

    function allocate(bytes memory _data, address _sender) external payable override {}

    function getPayout(uint256[] memory _applicationId, bytes memory _data)
        external
        view
        override
        returns (PayoutSummary[] memory summaries)
    {
        // todo:
    }

    function readyToPayout(bytes calldata) external view returns (bool) {
        // todo:
    }
}
