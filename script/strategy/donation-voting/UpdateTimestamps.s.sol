// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

// import {DonationVotingMerkleDistributionBaseStrategy} from
//     "../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/_poc/donation-voting/DonationVotingStrategy.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to update the timestamps test data for the Allo V2 contracts
/// @dev The issue witht he timestamp update is the deployed contract is using uint256 and the script is using uint64
///      as defined in the current contract.
///  Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/donation-voting/UpdateTimestamps.s.sol:UpdateTimestamps --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract UpdateTimestamps is Script, GoerliConfig {
    // Initialize Strategy
    DonationVotingStrategy strategy = DonationVotingStrategy(payable(address(DONATIONVOTINGSTRATEGY)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        strategy.updatePoolTimestamps(
            uint64(block.timestamp + 10),
            uint64(block.timestamp + 20000),
            uint64(block.timestamp + 30000),
            uint64(block.timestamp + 40000)
        );

        vm.stopBroadcast();
    }
}
