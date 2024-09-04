// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {DonationVotingOnchain} from "strategies/examples/donation-voting/DonationVotingOnchain.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationDonationVotingOnchainBase is IntegrationBase {
    uint256 internal constant POOL_AMOUNT = 1000;

    IAllo internal allo;
    DonationVotingOnchain internal strategy;

    address internal allocationToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    address internal allocator0;
    address internal allocator1;

    uint256 internal poolId;

    uint64 internal registrationStartTime;
    uint64 internal registrationEndTime;
    uint64 internal allocationStartTime;
    uint64 internal allocationEndTime;
    uint64 internal withdrawalCooldown = 1 days;

    function setUp() public virtual override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        allocator0 = makeAddr("allocator0");
        allocator1 = makeAddr("allocator1");

        // Deploying contracts
        strategy = new DonationVotingOnchain(address(allo));

        // Deal
        deal(DAI, userAddr, POOL_AMOUNT);
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), POOL_AMOUNT);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);

        registrationStartTime = uint64(block.timestamp);
        registrationEndTime = uint64(block.timestamp + 7 days);
        allocationStartTime = uint64(block.timestamp + 7 days + 1);
        allocationEndTime = uint64(block.timestamp + 10 days);
        poolId = allo.createPoolWithCustomStrategy(
            profileId,
            address(strategy),
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    metadataRequired: false,
                    registrationStartTime: registrationStartTime,
                    registrationEndTime: registrationEndTime
                }),
                allocationStartTime,
                allocationEndTime,
                withdrawalCooldown,
                allocationToken,
                true
            ),
            DAI,
            POOL_AMOUNT,
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

        // NOTE: removing all the ETH from the strategy before testing
        vm.prank(address(strategy));
        address(0).call{value: address(strategy).balance}("");
    }
}

contract IntegrationDonationVotingOnchainReviewRecipients is IntegrationDonationVotingOnchainBase {
    function test_reviewRecipients() public {
        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        uint256 recipientsCounter = strategy.recipientsCounter();

        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Revert if the registration period has finished
        vm.warp(registrationEndTime + 1);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Rejected);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));
        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOnchainAllocateERC20 is IntegrationDonationVotingOnchainBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_allocate() public {
        vm.warp(allocationStartTime);
        deal(allocationToken, allocator0, 4 + 25);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategy), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.startPrank(address(allo));

        strategy.allocate(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 4 + 25);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOnchainAllocateETH is IntegrationDonationVotingOnchainBase {
    function setUp() public override {
        allocationToken = NATIVE;
        super.setUp();

        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_allocate() public {
        vm.warp(allocationStartTime);
        vm.deal(address(allo), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.startPrank(address(allo));

        strategy.allocate{value: 4 + 25}(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);

        assertEq(allocator0.balance, 0);
        assertEq(address(strategy).balance, 4 + 25);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOnchainDistributeERC20 is IntegrationDonationVotingOnchainBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();

        vm.warp(allocationStartTime);
        deal(allocationToken, allocator0, 4 + 25);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategy), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.startPrank(address(allo));
        strategy.allocate(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);
        vm.stopPrank();
    }

    function test_distribute() public {
        // Distribute funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(address(allo));

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        strategy.distribute(recipients, abi.encode(allocationToken), recipient0Addr);

        uint256 recipient0Matching = POOL_AMOUNT * 4 / 29;
        uint256 recipient1Matching = POOL_AMOUNT * 25 / 29;
        assertEq(IERC20(DAI).balanceOf(recipient0Addr), recipient0Matching);
        assertEq(IERC20(DAI).balanceOf(recipient1Addr), recipient1Matching);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), POOL_AMOUNT - (recipient0Matching + recipient1Matching));

        assertEq(IERC20(allocationToken).balanceOf(recipient0Addr), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1Addr), 25);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 0);

        vm.expectRevert(abi.encodeWithSelector(DonationVotingOnchain.NOTHING_TO_DISTRIBUTE.selector, recipient0Addr));
        strategy.distribute(recipients, abi.encode(allocationToken), recipient0Addr);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOnchainDistributeETH is IntegrationDonationVotingOnchainBase {
    function setUp() public override {
        allocationToken = NATIVE;
        super.setUp();

        // Review recipients
        vm.startPrank(userAddr);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();

        vm.warp(allocationStartTime);
        vm.deal(address(allo), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.prank(address(allo));
        strategy.allocate{value: 4 + 25}(recipients, amounts, abi.encode(allocationToken, bytes("")), allocator0);
    }

    function test_distribute() public {
        // Distribute funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(address(allo));

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;
        strategy.distribute(recipients, abi.encode(allocationToken), recipient0Addr);

        uint256 recipient0Matching = POOL_AMOUNT * 4 / 29;
        uint256 recipient1Matching = POOL_AMOUNT * 25 / 29;
        assertEq(IERC20(DAI).balanceOf(recipient0Addr), recipient0Matching);
        assertEq(IERC20(DAI).balanceOf(recipient1Addr), recipient1Matching);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), POOL_AMOUNT - (recipient0Matching + recipient1Matching));

        assertEq(recipient0Addr.balance, 4);
        assertEq(recipient1Addr.balance, 25);
        assertEq(address(strategy).balance, 0);

        vm.expectRevert(abi.encodeWithSelector(DonationVotingOnchain.NOTHING_TO_DISTRIBUTE.selector, recipient0Addr));
        strategy.distribute(recipients, abi.encode(allocationToken), recipient0Addr);

        vm.stopPrank();
    }
}
