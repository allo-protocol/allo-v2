// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IDistributionStrategy.sol";

contract MockDistribution is IDistributionStrategy {
    function isCloneable() external pure returns (bool) {
        return true;
    }

    function getOwnerIdentity() external view returns (string memory) {}

    function activateDistribution(bytes memory _inputData, bytes memory _allocStratData) external {}

    function distribute(bytes memory _data, address sender) external {}
}
