// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Allo, IAllo, Metadata} from "contracts/core/Allo.sol";
import {Registry, Anchor} from "contracts/core/Anchor.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";

import {Actors} from "./helpers/Actors.t.sol";
import {Utils} from "./helpers/Utils.t.sol";
import {FuzzERC20, ERC20} from "./helpers/FuzzERC20.sol";

contract Setup is Actors {
    uint256 percentFee;
    uint256 baseFee;

    Allo allo;
    Registry registry;

    DirectAllocationStrategy strategy_directAllocation;

    ERC20 token;

    address protocolDeployer = makeAddr("protocolDeployer");
    address proxyOwner = makeAddr("proxyOwner");
    address treasury = makeAddr("treasury");
    address forwarder = makeAddr("forwarder");

    constructor() {
        // Deploy Allo
        vm.prank(protocolDeployer);
        address implementation = address(new Allo());

        // Deploy the registry
        vm.prank(protocolDeployer);
        registry = new Registry();

        // Deploy the proxy, pointing to the implementation
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(implementation, proxyOwner, "");

        allo = Allo(payable(address(proxy)));

        // Initialize
        vm.prank(protocolDeployer);
        allo.initialize(protocolDeployer, address(registry), payable(treasury), percentFee, baseFee, forwarder);

        // Deploy base strategy
        strategy_directAllocation = new DirectAllocationStrategy(address(allo));

        // Deploy token
        token = ERC20(address(new FuzzERC20()));

        // Create profile for 4 addresses
        for (uint256 i; i < 4; i++) {
            bytes32 _id = registry.createProfile(
                0, "a", Metadata({protocol: i + 1, pointer: ""}), _ghost_actors[i], new address[](0)
            );

            _addAnchorToActor(_ghost_actors[i], registry.getProfileById(_id).anchor, _id);
        }
    }
}
