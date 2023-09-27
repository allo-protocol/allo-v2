pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../contracts/core/Allo.sol";

import {Native} from "../contracts/core/libraries/Native.sol";
import {Config} from "./Config.sol";

contract AddToCloneableStrategy is Script, Native, Config {
     // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        allo.addToCloneableStrategies(DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE);

        vm.stopBroadcast();
    }
}
