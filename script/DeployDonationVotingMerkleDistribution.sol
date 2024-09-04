// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DonationVotingMerkleDistribution} from
    "contracts/strategies/examples/donation-voting/DonationVotingMerkleDistribution.sol";

contract DeployDonationVotingMerkleDistribution is DeployBase {
    function setUp() public {
        // Mainnet
        address _allo = 0x0000000000000000000000000000000000000000;
        bool _directTransfer = false;
        _deploymentParams[1] = abi.encode(_allo, _directTransfer);
    }

    function _deploy(uint256, bytes memory _data) internal override returns (address _contract) {
        (address _allo, bool _directTransfer) = abi.decode(_data, (address, bool));
        return address(new DonationVotingMerkleDistribution(_allo, _directTransfer));
    }
}
