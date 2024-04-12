// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {GameManagerStrategy} from "../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";

contract DeployGameManager is Script {
    string public constant versionName = "GameManager v1.3";
    address public constant AlloAddress = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(pk);

        vm.startBroadcast(deployer);

        GameManagerStrategy gameManager = new GameManagerStrategy(AlloAddress, versionName);

        vm.stopBroadcast();

        console2.log("GameManager: ", address(gameManager));
    }
}
