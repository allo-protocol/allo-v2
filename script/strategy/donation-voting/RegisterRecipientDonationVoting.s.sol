// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {IRegistry} from "../../../contracts/core/interfaces/IRegistry.sol";

import {DonationVotingStrategy} from "../../../contracts/strategies/_poc/donation-voting/DonationVotingStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/donation-voting/RegisterRecipientDonationVoting.s.sol:RegisterRecipientDonationVoting --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract RegisterRecipientDonationVoting is Script, GoerliConfig {
    bytes32 profileId = TEST_PROFILE_2;

    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    // Initialize Strategy
    DonationVotingStrategy strategy = DonationVotingStrategy(payable(address(DONATIONVOTINGSTRATEGY)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // IRegistry.Profile memory profile = registry.getProfileById(profileId);

        // Register 2 recipients
        Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        // Metadata memory recipientMetadata2 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});

        // data should be encoded: (recipientId, recipientAddress, metadata) this strategy uses the anchor
        bytes memory recipientData1 = abi.encode(OWNER, OWNER, recipientMetadata1);
        // bytes memory recipientData2 = abi.encode(OWNER, OWNER, recipientMetadata2);

        // FIXME: failing here 🚨
        allo.registerRecipient(TEST_POOL_1, recipientData1);
        // allo.registerRecipient(TEST_POOL_1, recipientData2);

        // DonationVotingStrategy.ApplicationStatus[] memory statuses =
        // new DonationVotingStrategy.ApplicationStatus[](
        //         2
        //     );

        // // Approve 1 recipient
        // statuses[0] = DonationVotingStrategy.ApplicationStatus({index: 0, statusRow: 1});

        // // Reject 1 recipient
        // statuses[1] = DonationVotingStrategy.ApplicationStatus({index: 1, statusRow: 1});

        // strategy.reviewRecipients(statuses);

        vm.stopBroadcast();
    }
}
