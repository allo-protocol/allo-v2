// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DonationVotingOffchain} from "contracts/strategies/examples/donation-voting/DonationVotingOffchain.sol";

contract DeployDonationVotingOffchain is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");
        bool _directTransfer = vm.envBool("DONATION_VOTING_OFFCHAIN_IS_DIRECT_TRANSFER");

        _contract = address(new DonationVotingOffchain(_allo, _directTransfer));
        _contractName = "DonationVotingOffchainStrategy";
    }
}
