// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {QVImpactStreamStrategy} from "../../../contracts/strategies/_poc/qv-impact-stream/QVImpactStreamStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create pool test data for the Impact Stream Strategy
/// `forge script script/strategy/qv-impact-stream/CreateImpactStreamPool.s.sol:CreateImpactStreamPool --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv`
contract CreateImpactStreamPool is Script, Native, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes memory encodedStrategyData = abi.encode(
            QVImpactStreamStrategy.InitializeParams(uint64(block.timestamp + 500), uint64(block.timestamp + 10000), 10)
        );

        Metadata memory metadata = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        address[] memory managers = new address[](1);
        managers[0] = address(OWNER);

        allo.createPool{value: 1e16}(
            TEST_PROFILE_2,
            address(IMPACTSTREAMFORCLONE),
            encodedStrategyData,
            NATIVE,
            1e16,
            metadata,
            managers
        );

        vm.stopBroadcast();
    }
}

// struct InitializeParams {
//         uint64 allocationStartTime;
//         uint64 allocationEndTime;
//         uint256 maxVoiceCreditsPerAllocator;
//     }
