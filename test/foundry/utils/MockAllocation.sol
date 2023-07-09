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

    function registerRecipients(bytes memory, address) external payable override returns (address) {
        return address(1);
    }

    function getRecipientStatus(address) external view override returns (RecipientStatus) {}

    function allocate(bytes memory, address) external payable override {}

    function getPayout(address[] memory, bytes memory)
        external
        view
        override
        returns (PayoutSummary[] memory summaries)
    {}

    function readyToPayout(bytes calldata) external view returns (bool) {}
}
