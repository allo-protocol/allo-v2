// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IAllocationStrategy.sol";

contract MockAllocation is IAllocationStrategy {
    function getOwnerIdentity() external view returns (string memory) {}

    function applyToPool(bytes memory, address) external payable returns (uint256) {
        return 1;
    }

    function getApplicationStatus(uint256) external view returns (ApplicationStatus) {
        // return ApplicationStatus.Applied;
    }

    function allocate(bytes memory, address) external payable returns (uint256) {}

    function generatePayouts() external payable returns (bytes memory) {}
}
