// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {DonationVotingStrategy} from "../../../contracts/strategies/_poc/donation-voting/DonationVotingStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create pool test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/donation-voting/CreateDonationVotingPool.s.sol:CreateDonationVotingPool --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateDonationVotingPool is Script, Native, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create A Pool using Donation Voting Merkle Distribution V1
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(NATIVE);

        bytes memory encodedStrategyData = abi.encode(
            DonationVotingStrategy.InitializeData(
                false,
                false,
                uint64(block.timestamp + 500),
                uint64(block.timestamp + 10000),
                uint64(block.timestamp + 20000),
                uint64(block.timestamp + 30000),
                allowedTokens
            )
        );

        Metadata memory metadata = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        address[] memory managers = new address[](1);
        managers[0] = address(OWNER);

        allo.createPool{value: 1e16}(
            TEST_PROFILE_2, address(DONATIONVOTINGSTRATEGY), encodedStrategyData, NATIVE, 1e16, metadata, managers
        );

        vm.stopBroadcast();
    }
}

// struct InitializeData {
//     bool useRegistryAnchor;
//     bool metadataRequired;
//     uint64 registrationStartTime;
//     uint64 registrationEndTime;
//     uint64 allocationStartTime;
//     uint64 allocationEndTime;
//     address[] allowedTokens;
// }
