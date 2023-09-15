// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../contracts/core/Allo.sol";
import {IRegistry} from "../contracts/core/interfaces/IRegistry.sol";

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";
import {Config} from "./Config.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/RegisterRecipient.s.sol:RegisterRecipient --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract RegisterRecipient is Script, Config {
    bytes32 profileId = TEST_PROFILE_1;

    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    // Initialize Strategy
    DonationVotingMerkleDistributionBaseStrategy strategy =
        DonationVotingMerkleDistributionBaseStrategy(payable(address(DONATIONVOTINGMERKLEPAYOUTSTRATEGY)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IRegistry.Profile memory profile = registry.getProfileById(profileId);

        // Register 2 recipients
        Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: "TestRecipientMetadataPointer1"});
        Metadata memory recipientMetadata2 = Metadata({protocol: 1, pointer: "TestRecipientMetadataPointer2"});

        // data should be encoded: (recipientId, recipientAddress, metadata) this strategy uses the anchor
        bytes memory recipientData1 = abi.encode(profile.anchor, OWNER, recipientMetadata1);
        bytes memory recipientData2 = abi.encode(profile.anchor, OWNER, recipientMetadata2);
        allo.registerRecipient(TEST_POOL_1, recipientData1);
        allo.registerRecipient(TEST_POOL_1, recipientData2);

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
        new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](
                2
            );

        // Approve 1 recipient
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 2});

        // Reject 1 recipient
        statuses[1] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 1, statusRow: 3});

        strategy.reviewRecipients(statuses);

        vm.stopBroadcast();
    }
}
