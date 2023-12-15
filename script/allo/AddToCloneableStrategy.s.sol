pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../contracts/core/Allo.sol";

import {Native} from "../../contracts/core/libraries/Native.sol";
import {GoerliConfig} from "./../GoerliConfig.sol";

/// `forge script script/allo/AddToCloneableStrategy.s.sol:AddToCloneableStrategy --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv`
contract AddToCloneableStrategy is Script, Native, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        allo.addToCloneableStrategies(IMPACTSTREAMFORCLONE);

        vm.stopBroadcast();
    }
}
