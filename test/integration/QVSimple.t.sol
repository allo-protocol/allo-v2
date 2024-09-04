// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {QVSimple} from "strategies/examples/quadratic-voting/QVSimple.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationQVSimple is IntegrationBase {
    IAllo public allo;
    QVSimple public strategy;

    address public allocator0;
    address public allocator1;

    uint256 public poolId;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        allocator0 = makeAddr("allocator0");
        allocator1 = makeAddr("allocator1");

        // Deploying contracts
        strategy = new QVSimple(address(allo));

        // Deal
        deal(DAI, userAddr, 100000 ether);
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), 100000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);
        poolId = allo.createPoolWithCustomStrategy(
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
                    maxVoiceCreditsPerAllocator: 100,
                    isUsingAllocationMetadata: false
                })
            ),
            DAI,
            100000 ether,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // Adding allocators
        address[] memory allocators = new address[](2);
        allocators[0] = allocator0;
        allocators[1] = allocator1;
        vm.prank(userAddr);
        strategy.addAllocators(allocators);

        // Adding recipients
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        bytes[] memory data = new bytes[](1);

        recipients[0] = recipient0Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient0Addr);

        recipients[0] = recipient1Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient1Addr);

        recipients[0] = recipient2Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient2Addr);

        vm.stopPrank();

        // Review recipients (Mark them as accepted)
        vm.startPrank(userAddr);

        // TODO: make them in batch
        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0Addr, 2, address(strategy));
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient1Addr, 2, address(strategy));
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient2Addr, 2, address(strategy));
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        vm.stopPrank();
    }

    function test_Allocate() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        recipients[2] = recipient2Addr;

        // Allocator 0
        uint256[] memory amounts0 = new uint256[](3);
        amounts0[0] = 10;
        amounts0[1] = 20;
        amounts0[2] = 30;

        vm.prank(address(allo));
        strategy.allocate(recipients, amounts0, "", allocator0);
        assertEq(strategy.voiceCreditsAllocated(allocator0), 60);

        // Allocator 1
        uint256[] memory amounts1 = new uint256[](3);
        amounts1[0] = 50;
        amounts1[1] = 20;
        amounts1[2] = 10;

        vm.prank(address(allo));
        strategy.allocate(recipients, amounts1, "", allocator1);
        assertEq(strategy.voiceCreditsAllocated(allocator1), 80);
    }

    function test_Distribute() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        recipients[2] = recipient2Addr;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        vm.prank(address(allo));
        strategy.allocate(recipients, amounts, "", allocator0);

        // Advance time
        vm.roll(1);
        vm.warp(block.timestamp + 8 days);

        vm.prank(address(allo));
        strategy.distribute(recipients, "", userAddr);

        assertEq(IERC20(DAI).balanceOf(recipient0Addr), 25000 ether);
        assertApproxEqRel(IERC20(DAI).balanceOf(recipient1Addr), 33333.33 ether, 0.01e18);
        assertApproxEqRel(IERC20(DAI).balanceOf(recipient2Addr), 41666.66 ether, 0.01e18);
    }
}
