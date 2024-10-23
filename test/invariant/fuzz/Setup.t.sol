// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Allo, IAllo, Metadata} from "contracts/core/Allo.sol";
import {Registry, Anchor} from "contracts/core/Anchor.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";

import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";

import {Actors} from "./helpers/Actors.t.sol";
import {Pools} from "./helpers/Pools.t.sol";
import {Utils} from "./helpers/Utils.t.sol";
import {FuzzERC20, ERC20} from "./helpers/FuzzERC20.sol";

contract Setup is Actors, Pools {
    uint256 percentFee;
    uint256 baseFee;

    uint64 defaultRegistrationStartTime;
    uint64 defaultRegistrationEndTime;
    uint256 defaultAllocationStartTime;
    uint256 defaultAllocationEndTime;
    uint256 defaultWithdrawalCooldown;
    uint256 DEFAULT_MAX_BID;

    Allo allo;
    Registry registry;

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

        // Deploy strategies implementations
        _initImplementations(address(allo));

        // strategy_directAllocation = new DirectAllocationStrategy(address(allo));

        // Deploy token
        token = ERC20(address(new FuzzERC20()));

        // Create profile for 4 addresses
        for (uint i; i < 4; i++) {
            bytes32 _id = registry.createProfile(
                0,
                "a",
                Metadata({protocol: i + 1, pointer: ""}),
                _ghost_actors[i],
                new address[](0)
            );

            _addAnchorToActor(
                _ghost_actors[i],
                registry.getProfileById(_id).anchor
            );
        }

        // Create pools for each strategy
        _initPools();
    }

    function _initPools() internal {
        defaultRegistrationStartTime = uint64(block.timestamp);
        defaultRegistrationEndTime = uint64(block.timestamp + 7 days);
        defaultAllocationStartTime = uint64(block.timestamp + 7 days + 1);
        defaultAllocationEndTime = uint64(block.timestamp + 10 days);
        defaultWithdrawalCooldown = 1 days;
        DEFAULT_MAX_BID = 1000;

        for (uint256 i = 1; i <= uint256(type(PoolStrategies).max); i++) {
            address _deployer = _ghost_actors[i % 4];

            IRegistry.Profile memory profile = registry.getProfileByAnchor(
                _ghost_anchorOf[_deployer]
            );

            bytes memory _metadata;

            if (PoolStrategies(i) == PoolStrategies.DirectAllocation) {
                _metadata = "";
            } else if (PoolStrategies(i) == PoolStrategies.DonationVoting) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: defaultRegistrationStartTime,
                        registrationEndTime: defaultRegistrationEndTime
                    }),
                    defaultAllocationStartTime,
                    defaultAllocationEndTime,
                    defaultWithdrawalCooldown,
                    token,
                    true
                );
            } else if (
                PoolStrategies(i) == PoolStrategies.EasyRPGF
            ) {} else if (PoolStrategies(i) == PoolStrategies.ImpactStream) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    QVSimple.QVSimpleInitializeData({
                        allocationStartTime: uint64(block.timestamp),
                        allocationEndTime: uint64(block.timestamp + 7 days),
                        maxVoiceCreditsPerAllocator: 100,
                        isUsingAllocationMetadata: false
                    })
                );
            } else if (PoolStrategies(i) == PoolStrategies.QuadraticVoting) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    QVSimple.QVSimpleInitializeData({
                        allocationStartTime: uint64(block.timestamp),
                        allocationEndTime: uint64(block.timestamp + 7 days),
                        maxVoiceCreditsPerAllocator: 100,
                        isUsingAllocationMetadata: false
                    })
                );
            } else if (PoolStrategies(i) == PoolStrategies.RFP) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    DEFAULT_MAX_BID
                );
            } else if (PoolStrategies(i) == PoolStrategies.SQFSuperfluid) {
                // Skip for now - mock?
                return;
            }

            vm.prank(_deployer);
            uint256 _poolId = allo.createPool(
                profile.id,
                _strategyImplementations[PoolStrategies(i)],
                _metadata,
                address(token),
                0,
                profile.metadata,
                new address[](0)
            );

            ghost_poolAdmins[_poolId] = _deployer;

            _recordPool(_poolId, PoolStrategies(i));
        }
    }
}
