// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {RFPSimple, Errors} from "contracts/strategies/RFPSimple.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IMilestonesExtension} from "contracts/extensions/interfaces/IMilestonesExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntegrationRFPSimple is Test {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public constant DAI_FUNDS = 10;

    Allo public allo;
    Registry public registry;
    RFPSimple public strategy;

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

    function _getApplicationStatus(address _recipientId, uint256 _status)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        uint256 recipientIndex = strategy.recipientToStatusIndexes(_recipientId) - 1;

        uint256 rowIndex = recipientIndex / 64;
        uint256 colIndex = (recipientIndex % 64) * 4;
        uint256 currentRow = strategy.statusesBitMap(rowIndex);
        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

    function _getApplicationStatus(address[] memory _recipientIds, uint256[] memory _statuses)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        uint256 recipientIndex = strategy.recipientToStatusIndexes(_recipientIds[0]) - 1;
        uint256 rowIndex = recipientIndex / 64;
        uint256 statusRow = strategy.statusesBitMap(rowIndex);
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            recipientIndex = strategy.recipientToStatusIndexes(_recipientIds[i]) - 1;
            require(rowIndex == recipientIndex / 64, "_recipientIds belong to different rows");
            uint256 colIndex = (recipientIndex % 64) * 4;
            uint256 newRow = statusRow & ~(15 << colIndex);
            statusRow = newRow | (_statuses[i] << colIndex);
        }

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

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
        strategy = new RFPSimple(address(allo));

        // Initialize contracts
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1)); // NOTE: trusted forwarder is not used
        registry.initialize(owner);

        // Creating profile
        vm.prank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Deal
        deal(DAI, profileOwner, DAI_FUNDS);
        vm.prank(profileOwner);
        IERC20(DAI).approve(address(allo), DAI_FUNDS);

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
                IMilestonesExtension.InitializeParams({maxBid: uint256(1000)})
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
        bytes[] memory extraData = new bytes[](1);

        recipients[0] = recipient0;
        uint256 proposalBid = 10;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient0);

        recipients[0] = recipient1;
        proposalBid = 20;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient1);

        recipients[0] = recipient2;
        proposalBid = 30;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient2);

        vm.stopPrank();
    }

    function testReviewRecipients() public {
        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        uint256 recipientsCounter = strategy.recipientsCounter();

        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Block multiple acceptances
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);
        vm.expectRevert(Errors.INVALID.selector);
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Correctly set statuses
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Rejected);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Registration has ended
        assertEq(uint256(strategy.registrationEndTime()), block.timestamp - 1);
        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);
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
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0, uint256(IRecipientsExtension.Status.Accepted));
        strategy.reviewRecipients(statuses, strategy.recipientsCounter());

        // Set milestones
        IMilestonesExtension.Milestone[] memory _milestones = new IMilestonesExtension.Milestone[](2);
        _milestones[0].amountPercentage = 0.6 ether;
        _milestones[1].amountPercentage = 0.4 ether;
        strategy.setMilestones(_milestones);

        // Submit milestone
        vm.startPrank(recipient0);
        Metadata memory _metadata;
        strategy.submitUpcomingMilestone(recipient0, _metadata);

        // Accept milestone
        vm.startPrank(profileOwner);
        strategy.reviewMilestone(IMilestonesExtension.MilestoneStatus.Accepted);

        // Distribute funds
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        recipients[0] = recipient0;
        uint256[] memory _milestonesIds = new uint256[](2);

        // Revert when attempting to claim twice
        _milestonesIds[0] = 0;
        _milestonesIds[1] = 0;
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_INVALID_MILESTONE_STATUS.selector);
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0);

        // Revert when attempting to claim non-submitted milestone
        _milestonesIds[1] = 1;
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_INVALID_MILESTONE_STATUS.selector);
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0);

        // Distribute
        _milestonesIds = new uint256[](1);
        _milestonesIds[0] = 0;
        strategy.distribute(recipients, abi.encode(_milestonesIds), recipient0);

        assertEq(IERC20(DAI).balanceOf(recipient0), 6);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), 4);
        vm.stopPrank();
    }
}
