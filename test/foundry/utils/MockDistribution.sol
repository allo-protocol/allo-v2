// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/interfaces/IDistributionStrategy.sol";

contract MockDistribution is IDistributionStrategy {
    /// 
    function getOwnerIdentity() external view returns (string memory) {
        // Todo:
    }

    // decode the _data into what's relevant to determine payouts
    // default will be a struct with a list of addresses and WAD percentages
    // turn "on" the abilty to distribute payouts
    function activateDistribution(bytes memory _inputData, bytes memory _allocStratData) external {
        // Todo:
    }

    // distribution a payout based on the strategy's needs
    // this could include merkle proofs, etc or just nothing
    function distribute(bytes memory _data, address sender) external {
        // todo:
    }
}
