// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {QVSimple} from "contracts/strategies/QVSimple.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";

contract IntegrationQVSimple is Test {
    Allo public allo;
    Registry public registry;
    QVSimple public strategy;

    address public owner;
    address public treasury;
    address public profileOwner;
    address public recipient0;
    address public recipient1;
    address public recipient2;
    address public allocator0;
    address public allocator1;

    bytes32 public profileId;

    uint256 public poolId;

    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20289932);

        owner = makeAddr("owner");
        treasury = makeAddr("treasury");
        profileOwner = makeAddr("profileOwner");
        recipient0 = makeAddr("recipient0");
        recipient1 = makeAddr("recipient1");
        recipient2 = makeAddr("recipient2");
        allocator0 = makeAddr("allocator0");
        allocator1 = makeAddr("allocator1");

        // Deploying contracts
        allo = new Allo();
        registry = new Registry();
        strategy = new QVSimple(address(allo));

        // Initialize contracts
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1)); // NOTE: trusted forwarder is not used
        registry.initialize(owner);

        // Creating profile
        vm.prank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = profileOwner;
        vm.prank(profileOwner);
        poolId = allo.createPool(
            profileId,
            address(strategy),
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    metadataRequired: false,
                    registrationStartTime: uint64(block.timestamp),
                    registrationEndTime: uint64(block.timestamp + 7 days)
                }),
                QVSimple.QVSimpleInitializeData({
                    allocationStartTime: uint64(block.timestamp),
                    allocationEndTime: uint64(block.timestamp + 7 days),
                    maxVoiceCreditsPerAllocator: 100
                })
            ),
            dai,
            0,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // // Adding allocators
        // vm.startPrank(profileOwner);
        // strategy.addAllocator(allocator0);
        // strategy.addAllocator(allocator1);

        // // Adding recipients
        // vm.startPrank(address(allo));

        // address[] memory recipients = new address[](1);
        // recipients[0] = recipient0;
        // strategy.register(recipients, abi.encode(address(0), Metadata({protocol: 0, pointer: ""})), recipient0);
    }

    function test_Allocate() public {
        assertEq(poolId, strategy.getPoolId());
    }
}
