// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DonationVotingMerkleDistribution} from
    "contracts/strategies/examples/donation-voting/DonationVotingMerkleDistribution.sol";

contract DeployDonationVotingMerkleDistribution is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");
        bool _directTransfer = vm.envBool("DONATION_VOTING_MERKLE_DISTRIBUTION_IS_DIRECT_TRANSFER");

        _contract = address(new DonationVotingMerkleDistribution(_allo, _directTransfer));
        _contractName = "DonationVotingMerkleDistributionStrategy";
    }
}
