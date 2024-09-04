// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DonationVotingOffchain} from "contracts/strategies/examples/donation-voting/DonationVotingOffchain.sol";

contract DeployDonationVotingOffchain is DeployBase {
    function setUp() public {
        // Mainnet
        address _allo = 0x0000000000000000000000000000000000000000;
        bool _directTransfer = false;
        _deploymentParams[1] = abi.encode(_allo, _directTransfer);
    }

    function _deploy(uint256, bytes memory _data) internal override returns (address _contract) {
        (address _allo, bool _directTransfer) = abi.decode(_data, (address, bool));
        return address(new DonationVotingOffchain(_allo, _directTransfer));
    }
}
