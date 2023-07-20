//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Registry} from "../contracts/core/Registry.sol";

contract DeployRegistry is Script {
    function run() public {
        console.log("Deploying Registry...");
        console.log("Deployer: %s", msg.sender);
        console.log("Balance: %s", address(msg.sender).balance);

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Registry
        Registry registry = new Registry(msg.sender);
        console.log("Registry Deployed at %s", address(registry));

        vm.stopBroadcast();
    }
}

// forge script script/Registry.s.sol:DeployRegistry --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vv
