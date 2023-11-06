// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

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
            QVImpactStreamStrategy.InitializeParams(
                false, false, uint64(block.timestamp + 500), uint64(block.timestamp + 10000), 10
            )
        );

        console.log("Allo ==> %s", ALLO);

        Metadata memory metadata = Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1});
        address[] memory managers = new address[](3);
        managers[0] = address(OWNER);
        managers[1] = 0xB8cEF765721A6da910f14Be93e7684e9a3714123;
        managers[2] = 0xE7eB5D2b5b188777df902e89c54570E7Ef4F59CE;

        uint256 poolId = allo.createPool{value: 1e16}(
            POOL_CREATOR_PROFILE_ID,
            address(IMPACTSTREAMFORCLONE),
            encodedStrategyData,
            NATIVE,
            1e16,
            metadata,
            managers
        );

        Allo.Pool memory pool = allo.getPool(poolId);
        console.log("poolId ==> %s", poolId);
        console.log("strategy ==> %s", address(pool.strategy));

        vm.stopBroadcast();
    }
}
