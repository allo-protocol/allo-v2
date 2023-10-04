// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {IRegistry} from "../../../contracts/core/interfaces/IRegistry.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {RFPSimpleStrategy} from "../../../contracts/strategies/rfp-simple/RFPSimpleStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Register recipients and set their status ~
/// Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/rfp-simple/CreateMilestoneRFPSimple.s.sol:CreateMilestoneRFPSimple --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateMilestoneRFPSimple is Script, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(REGISTRY);

    // Initialize Strategy
    RFPSimpleStrategy strategy = RFPSimpleStrategy(payable(address(RFPSIMPLESTRATEGY)));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // IRegistry.Profile memory profile = registry.getProfileById(TEST_PROFILE_2);

        RFPSimpleStrategy.Milestone[] memory milestones = new RFPSimpleStrategy.Milestone[](2);
        RFPSimpleStrategy.Milestone memory milestone1 = RFPSimpleStrategy.Milestone({
            amountPercentage: 25e16,
            metadata: Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1}),
            milestoneStatus: IStrategy.Status.Pending
        });
        RFPSimpleStrategy.Milestone memory milestone2 = RFPSimpleStrategy.Milestone({
            amountPercentage: 75e16,
            metadata: Metadata({protocol: 1, pointer: TEST_METADATA_POINTER_1}),
            milestoneStatus: IStrategy.Status.Pending
        });
        milestones[0] = milestone1;
        milestones[1] = milestone2;

        strategy.setMilestones(milestones);

        vm.stopBroadcast();
    }
}

// struct Milestone {
//         uint256 amountPercentage;
//         Metadata metadata;
//         Status milestoneStatus;
//     }
