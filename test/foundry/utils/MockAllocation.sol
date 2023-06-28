// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IAllocationStrategy.sol";

contract MockAllocation is IAllocationStrategy {
    function isCloneable() external pure returns (bool) {
        return true;
    }

    function getOwnerIdentity() external view returns (string memory) {}

    function applyToPool(bytes memory _data, address sender) external payable returns (uint256) {}

    function getApplicationStatus(uint256 applicationId) external view returns (ApplicationStatus) {}

    function allocate(bytes memory _data, address sender) external payable returns (uint256) {}

    function generatePayouts() external payable returns (bytes memory) {}
}
