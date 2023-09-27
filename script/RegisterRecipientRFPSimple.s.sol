// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../contracts/core/Allo.sol";
import {IRegistry} from "../contracts/core/interfaces/IRegistry.sol";

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./GoerliConfig.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/RegisterRecipientRFPSimple.s.sol:RegisterRecipientRFPSimple --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract RegisterRecipientRFPSimple is Script, GoerliConfig {
    bytes32 profileId = TEST_PROFILE_2;

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
        Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        Metadata memory recipientMetadata2 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});

        // data should be encoded: (recipientId, recipientAddress, metadata) this strategy uses the anchor
        bytes memory recipientData1 = abi.encode(profile.anchor, 2e18, recipientMetadata1);
        bytes memory recipientData2 = abi.encode(profile.anchor, 15e17, recipientMetadata2);

        allo.registerRecipient(TEST_POOL_1, recipientData1);
        allo.registerRecipient(TEST_POOL_1, recipientData2);

        vm.stopBroadcast();
    }
}
