// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IAllocationStrategy.sol";

contract MockAllocation is IAllocationStrategy {
    bytes32 public identityId;
    address public allo;
    uint256 public poolId;
    bool public initialized;

    function initialize(bytes32, uint256, address, bytes memory) external {
        if (initialized) {
            revert();
        }
        initialized = true;
    }

    function getOwnerIdentity() external view returns (string memory) {}

    function addRecipient(bytes memory, address) external payable returns (uint256) {
        return 1;
    }

    function getApplicationStatus(uint256) external view returns (ApplicationStatus) {
        // return ApplicationStatus.Applied;
    }

    function allocate(bytes memory, address) external payable returns (uint256) {}

    function generatePayouts() external payable returns (bytes memory) {}
}
