// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {IRegistry} from "../../../contracts/core/interfaces/IRegistry.sol";

import {QVImpactStreamStrategy} from "../../../contracts/strategies/_poc/qv-impact-stream/QVImpactStreamStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create test data for the Allo V2 strategy contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/qv-impact-stream/RegisterRecipientQVImpactStream.s.sol:RegisterRecipientQVImpactStream --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract RegisterRecipientQVImpactStream is Script, GoerliConfig {
    bytes32 profileId = TEST_PROFILE_2;

    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    // Initialize Strategy
    QVImpactStreamStrategy strategy = QVImpactStreamStrategy(payable(address(IMPACTSTREAM)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Register 2 recipients
        Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        // IRegistry.Profile memory profile = registry.getProfileByAnchor(OWNER);

        // data should be encoded: (address, address, uint256, Metadata)
        bytes memory recipientData1 = abi.encode(OWNER, OWNER, 1e17, recipientMetadata1);

        allo.registerRecipient(TEST_POOL_1, recipientData1);

        vm.stopBroadcast();
    }
}
