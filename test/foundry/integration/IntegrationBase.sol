// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Allo, IAllo} from "contracts/core/Allo.sol";
import {ITransparentUpgradeableProxy} from "./ITransparentUpgradeableProxy.sol";
import {IOwnable} from "./IOwnable.sol";

abstract contract IntegrationBase is Test {
    address public constant ALLO_PROXY = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
    address public constant BICONOMY_FORWARDER = 0x84a0856b038eaAd1cC7E297cF34A7e72685A8693;

    address public alloAdmin;
    address public owner;
    address public registry;
    address public treasury;

    uint256 public percentFee;
    uint256 public baseFee;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20289932);

        // Get the current protocol variables
        // alloAdmin = ITransparentUpgradeableProxy(ALLO_PROXY).admin();
        alloAdmin = address(
            uint160(uint256(vm.load(ALLO_PROXY, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)))
        );
        owner = IOwnable(ALLO_PROXY).owner();
        registry = address(IAllo(ALLO_PROXY).getRegistry());
        treasury = address(IAllo(ALLO_PROXY).getTreasury());
        percentFee = IAllo(ALLO_PROXY).getPercentFee();
        baseFee = IAllo(ALLO_PROXY).getBaseFee();

        // Deploy the implementation
        vm.prank(alloAdmin);
        address implementation = address(new Allo());

        // Deploy the update
        vm.prank(alloAdmin);
        ITransparentUpgradeableProxy(ALLO_PROXY).upgradeTo(implementation);

        // Initialize
        vm.prank(owner);
        IAllo(ALLO_PROXY).initialize(owner, registry, payable(treasury), percentFee, baseFee, BICONOMY_FORWARDER);
    }
}
