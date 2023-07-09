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

    function registerRecipients(bytes memory, address) external payable override returns (uint256) {
        return 1;
    }

    function getRecipientStatus(uint256) external view override returns (RecipientStatus) {}

    function allocate(bytes memory, address) external payable override {}

    function getPayout(uint256[] memory, bytes memory)
        external
        view
        override
        returns (PayoutSummary[] memory summaries)
    {}

    function readyToPayout(bytes calldata) external view returns (bool) {}
}
