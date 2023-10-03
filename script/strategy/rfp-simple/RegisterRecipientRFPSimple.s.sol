// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {IRegistry} from "../../../contracts/core/interfaces/IRegistry.sol";

import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/rfp-simple/RegisterRecipientRFPSimple.s.sol:RegisterRecipientRFPSimple --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract RegisterRecipientRFPSimple is Script, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    // Initialize Strategy
    RFPSimpleStrategy strategy = RFPSimpleStrategy(payable(address(RFPSIMPLESTRATEGY)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IRegistry.Profile memory profile = registry.getProfileById(TEST_PROFILE_2);

        // Register recipients
        // Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        Metadata memory recipientMetadata2 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});

        // // data should be encoded: (recipientAddress, registryAnchor, proposalBid, metadata) this strategy does not use the anchor
        // bytes memory recipientData1 = abi.encode(OWNER, address(0), 2e17, recipientMetadata1);
        bytes memory recipientData2 = abi.encode(OWNER, profile.anchor, 15e17, recipientMetadata2);

        // allo.registerRecipient(TEST_POOL_1, recipientData1);
        allo.registerRecipient(TEST_POOL_1, recipientData2);

        vm.stopBroadcast();
    }
}
