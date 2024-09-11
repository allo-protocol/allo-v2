// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {QVImpactStream} from "strategies/examples/impact-stream/QVImpactStream.sol";
import {QVSimple} from "strategies/examples/quadratic-voting/QVSimple.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";

contract IntegrationQVImpactStream is Test {
    Allo public allo;
    Registry public registry;
    QVImpactStream public strategy;

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
        strategy = new QVImpactStream(address(allo));

        // Initialize contracts
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1)); // NOTE: trusted forwarder is not used
        registry.initialize(owner);

        // Creating profile
        vm.prank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Deal
        deal(dai, profileOwner, 100000 ether);
        vm.prank(profileOwner);
        IERC20(dai).approve(address(allo), 100000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = profileOwner;
        vm.prank(profileOwner);
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
            dai,
            100000 ether,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // Adding allocators
        vm.startPrank(profileOwner);
        address[] memory allocators = new address[](2);
        allocators[0] = allocator0;
        allocators[1] = allocator1;
        strategy.addAllocators(allocators);
        vm.stopPrank();

        // Adding recipients
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        bytes[] memory data = new bytes[](1);

        recipients[0] = recipient0;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient0);

        recipients[0] = recipient1;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient1);

        recipients[0] = recipient2;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}));
        strategy.register(recipients, abi.encode(data), recipient2);

        vm.stopPrank();

        // Review recipients (Mark them as accepted)
        vm.startPrank(profileOwner);

        // TODO: make them in batch
        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0, 2);
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient1, 2);
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient2, 2);
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        vm.stopPrank();
    }

    function _getApplicationStatus(address _recipientId, uint256 _status)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        IRecipientsExtension.Recipient memory recipient = strategy.getRecipient(_recipientId);
        uint256 recipientIndex = recipient.statusIndex - 1;

        uint256 rowIndex = recipientIndex / 64;
        uint256 colIndex = (recipientIndex % 64) * 4;
        uint256 currentRow = strategy.statusesBitMap(rowIndex);
        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

    function test_AllocateSetPayoutsDistributeFlow() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0;
        recipients[1] = recipient1;
        recipients[2] = recipient2;

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

        QVImpactStream.Payout[] memory payouts = new QVImpactStream.Payout[](3);
        payouts[0] = QVImpactStream.Payout({recipientId: recipient0, amount: 10});
        payouts[1] = QVImpactStream.Payout({recipientId: recipient1, amount: 20});
        payouts[2] = QVImpactStream.Payout({recipientId: recipient2, amount: 30});

        vm.warp(block.timestamp + 8 days);
        vm.prank(profileOwner);
        strategy.setPayouts(payouts);

        assertEq(strategy.getPayout(recipient0).amount, 10);
        assertEq(strategy.getPayout(recipient1).amount, 20);
        assertEq(strategy.getPayout(recipient2).amount, 30);

        vm.prank(address(allo));
        strategy.distribute(recipients, "", profileOwner);

        assertEq(IERC20(dai).balanceOf(recipient0), 10);
        assertEq(IERC20(dai).balanceOf(recipient1), 20);
        assertEq(IERC20(dai).balanceOf(recipient2), 30);
    }
}
