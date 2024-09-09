// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DonationVotingOnchain} from "contracts/strategies/examples/donation-voting/DonationVotingOnchain.sol";

contract DeployDonationVotingOnchain is DeployBase {
    function _deploy() internal override returns (address _contract) {
        address _allo = vm.envAddress("ALLO_ADDRESS");
        return address(new DonationVotingOnchain(_allo));
    }
}
