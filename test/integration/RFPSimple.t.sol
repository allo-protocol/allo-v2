// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {RFPSimple} from "strategies/examples/rfp/RFPSimple.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IMilestonesExtension} from "strategies/extensions/milestones/IMilestonesExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationRFPSimple is IntegrationBase {
    uint256 public constant DAI_FUNDS = 10;
    uint256 public constant MAX_BID = 1000;

    IAllo public allo;
    RFPSimple public strategy;

    address public allocator0;
    address public allocator1;

    uint256 public poolId;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        allocator0 = makeAddr("allocator0");
        allocator1 = makeAddr("allocator1");

        // Deploying contracts
        strategy = new RFPSimple(address(allo));

        // Deal
        deal(DAI, userAddr, DAI_FUNDS);
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), DAI_FUNDS);

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
                MAX_BID
            ),
            DAI,
            DAI_FUNDS,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // Adding recipients
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        bytes[] memory data = new bytes[](1);

        recipients[0] = recipient0Addr;
        uint256 proposalBid = 10;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient0Addr);

        recipients[0] = recipient1Addr;
        proposalBid = 20;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient1Addr);

        recipients[0] = recipient2Addr;
        proposalBid = 30;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient2Addr);

        vm.stopPrank();
    }

    function testReviewRecipients() public {
        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        uint256 recipientsCounter = strategy.recipientsCounter();

        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Block multiple acceptances
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));
        vm.expectRevert(Errors.INVALID.selector);
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Correctly set statuses
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Rejected);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Registration has ended
        assertEq(uint256(strategy.registrationEndTime()), block.timestamp - 1);
        vm.expectRevert(IRecipientsExtension.RecipientsExtension_RegistrationNotActive.selector);
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_Allocate() public {
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);
        strategy.allocate(recipients, amounts, "", address(0));
        vm.stopPrank();
    }

    function test_Distribute() public {
        // Accept (review) recipient
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] =
            _getApplicationStatus(recipient0Addr, uint256(IRecipientsExtension.Status.Accepted), address(strategy));
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        // Set milestones
        IMilestonesExtension.Milestone[] memory _milestones = new IMilestonesExtension.Milestone[](2);
        _milestones[0].amountPercentage = 0.6 ether;
        _milestones[1].amountPercentage = 0.4 ether;
        strategy.setMilestones(_milestones);

        // Submit milestone
        vm.startPrank(recipient0Addr);
        Metadata memory _metadata;
        strategy.submitUpcomingMilestone(recipient0Addr, _metadata);

        // Accept milestone
        vm.startPrank(userAddr);
        strategy.reviewMilestone(IMilestonesExtension.MilestoneStatus.Accepted);

        // Distribute funds
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        recipients[0] = recipient0Addr;
        uint256[] memory _milestonesIds = new uint256[](2);

        // Revert when attempting to claim twice
        _milestonesIds[0] = 0;
        _milestonesIds[1] = 0;
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidMilestoneStatus.selector);
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0Addr);

        // Revert when attempting to claim non-submitted milestone
        _milestonesIds[1] = 1;
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidMilestoneStatus.selector);
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0Addr);

        // Distribute
        _milestonesIds = new uint256[](1);
        _milestonesIds[0] = 0;
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0Addr);

        assertEq(IERC20(DAI).balanceOf(recipient0Addr), 6);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), 4);
        vm.stopPrank();
    }
}
