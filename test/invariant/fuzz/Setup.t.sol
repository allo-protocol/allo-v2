// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Allo, IAllo, Metadata} from "contracts/core/Allo.sol";
import {Registry, Anchor} from "contracts/core/Anchor.sol";

import {Actors} from "./helpers/Actors.t.sol";
import {Utils} from "./helpers/Utils.t.sol";

contract Setup is Actors, Utils {
    //   address public constant ALLO_PROXY = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
    //   address public constant BICONOMY_FORWARDER = 0x84a0856b038eaAd1cC7E297cF34A7e72685A8693;
    //   address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //   address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //   bytes32 public constant DOMAIN_SEPARATOR = 0x4fde6db5140ab711910b567033f2d5e64dc4f7123d722004dd748edf6ed07abb;

    //   address public userAddr;
    //   address public recipient0Addr;
    //   address public recipient1Addr;
    //   address public recipient2Addr;

    //   uint256 public userPk;
    //   uint256 public recipient0Pk;
    //   uint256 public recipient1Pk;
    //   uint256 public recipient2Pk;

    //   bytes32 public profileId;

    //   address public alloAdmin;
    //   address public owner;
    //   address public registry;
    //   address public treasury;
    //   address public relayer;

    uint256 percentFee;
    uint256 baseFee;

    Allo allo;
    Registry registry;

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
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            proxyOwner,
            ""
        );

        allo = Allo(payable(address(proxy)));

        // Initialize
        vm.prank(protocolDeployer);
        allo.initialize(
            protocolDeployer,
            address(registry),
            payable(treasury),
            percentFee,
            baseFee,
            forwarder
        );

        // Generate multiple profiles
        //
        // Use the deployer as owner of the first role
        vm.prank(msg.sender);

        bytes32 _id = registry.createProfile(
            0,
            "a",
            Metadata({protocol: 1, pointer: ""}),
            msg.sender,
            new address[](0)
        );
        _addActor(msg.sender);

        // todo: add a ghost sender->anchor (anchor->id is accessible via the registry)
    }
}
