// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {DonationVotingOffchain} from "strategies/examples/donation-voting/DonationVotingOffchain.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationDonationVotingOffchainBase is IntegrationBase {
    uint256 internal constant POOL_AMOUNT = 1000;

    IAllo internal allo;
    DonationVotingOffchain internal strategy;
    DonationVotingOffchain internal strategyWithDirectTransfers;

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

        strategy = new DonationVotingOffchain(address(allo), false);
        strategyWithDirectTransfers = new DonationVotingOffchain(address(allo), true);

        // Deal
        deal(DAI, userAddr, POOL_AMOUNT * 2);
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), POOL_AMOUNT * 2);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.startPrank(userAddr);

        registrationStartTime = uint64(block.timestamp);
        registrationEndTime = uint64(block.timestamp + 7 days);
        allocationStartTime = uint64(block.timestamp + 7 days + 1);
        allocationEndTime = uint64(block.timestamp + 10 days);
        address[] memory allowedTokens = new address[](0);

        // Deploy strategy with direct transfers disabled
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
                allowedTokens,
                true
            ),
            DAI,
            POOL_AMOUNT,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // Deploy strategy with direct transfers enabled
        allo.createPoolWithCustomStrategy(
            profileId,
            address(strategyWithDirectTransfers),
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    metadataRequired: false,
                    registrationStartTime: registrationStartTime,
                    registrationEndTime: registrationEndTime
                }),
                allocationStartTime,
                allocationEndTime,
                withdrawalCooldown,
                allowedTokens
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
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient0Addr);

        recipients[0] = recipient1Addr;
        proposalBid = 20;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient1Addr);
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient1Addr);

        recipients[0] = recipient2Addr;
        proposalBid = 30;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient2Addr);
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient2Addr);

        vm.stopPrank();

        // NOTE: removing all the ETH from the strategy before testing
        vm.prank(address(strategy));
        address(0).call{value: address(strategy).balance}("");
    }
}

contract IntegrationDonationVotingOffchainReviewRecipients is IntegrationDonationVotingOffchainBase {
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

contract IntegrationDonationVotingOffchainAllocateERC20 is IntegrationDonationVotingOffchainBase {
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

        address[] memory tokens = new address[](2);
        tokens[0] = allocationToken;
        tokens[1] = allocationToken;

        bytes[] memory permits = new bytes[](2);

        bytes memory data = abi.encode(tokens, permits);

        vm.startPrank(address(allo));

        strategy.allocate(recipients, amounts, data, allocator0);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 4 + 25);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainAllocateETH is IntegrationDonationVotingOffchainBase {
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

        deal(allocationToken, allocator0, 4);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategy), 4);

        vm.deal(address(allo), 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.startPrank(address(allo));

        address[] memory tokens = new address[](2);
        tokens[0] = allocationToken;
        tokens[1] = NATIVE;

        bytes[] memory permits = new bytes[](2);

        bytes memory data = abi.encode(tokens, permits);

        strategy.allocate{value: 25}(recipients, amounts, data, allocator0);

        assertEq(allocator0.balance, 0);
        assertEq(address(strategy).balance, 25);
        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 4);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainDirectAllocateERC20 is IntegrationDonationVotingOffchainBase {
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
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategyWithDirectTransfers));

        uint256 recipientsCounter = strategyWithDirectTransfers.recipientsCounter();
        strategyWithDirectTransfers.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_allocate() public {
        vm.warp(allocationStartTime);
        deal(allocationToken, allocator0, 4 + 25);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategyWithDirectTransfers), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        address[] memory tokens = new address[](2);
        tokens[0] = allocationToken;
        tokens[1] = allocationToken;

        bytes[] memory permits = new bytes[](2);

        bytes memory data = abi.encode(tokens, permits);

        vm.startPrank(address(allo));

        strategyWithDirectTransfers.allocate(recipients, amounts, data, allocator0);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategyWithDirectTransfers)), 0);
        assertEq(IERC20(allocationToken).balanceOf(recipient0Addr), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1Addr), 25);

        uint256 amountAllocated0 = strategyWithDirectTransfers.amountAllocated(recipient0Addr, allocationToken);
        uint256 amountAllocated1 = strategyWithDirectTransfers.amountAllocated(recipient1Addr, allocationToken);
        assertEq(amountAllocated0, 0);
        assertEq(amountAllocated1, 0);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategyWithDirectTransfers.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainDirectAllocateETH is IntegrationDonationVotingOffchainBase {
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
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategyWithDirectTransfers));

        uint256 recipientsCounter = strategyWithDirectTransfers.recipientsCounter();
        strategyWithDirectTransfers.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_allocate() public {
        vm.warp(allocationStartTime);

        deal(allocationToken, allocator0, 4);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategyWithDirectTransfers), 4);

        vm.deal(address(allo), 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 4;
        amounts[1] = 25;

        vm.startPrank(address(allo));

        address[] memory tokens = new address[](2);
        tokens[0] = allocationToken;
        tokens[1] = NATIVE;

        bytes[] memory permits = new bytes[](2);

        bytes memory data = abi.encode(tokens, permits);

        strategyWithDirectTransfers.allocate{value: 25}(recipients, amounts, data, allocator0);

        assertEq(allocator0.balance, 0);
        assertEq(address(strategyWithDirectTransfers).balance, 0);
        assertEq(recipient1Addr.balance, 25);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategyWithDirectTransfers)), 0);
        assertEq(IERC20(allocationToken).balanceOf(recipient0Addr), 4);

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategyWithDirectTransfers.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainClaim is IntegrationDonationVotingOffchainBase {
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

        address[] memory tokens = new address[](2);
        tokens[0] = allocationToken;
        tokens[1] = allocationToken;

        bytes[] memory permits = new bytes[](2);

        bytes memory data = abi.encode(tokens, permits);

        vm.startPrank(address(allo));
        strategy.allocate(recipients, amounts, data, allocator0);
        vm.stopPrank();
    }

    function test_claim() public {
        // Claim allocation funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(recipient0Addr);

        DonationVotingOffchain.Claim[] memory claims = new DonationVotingOffchain.Claim[](2);
        claims[0].recipientId = recipient0Addr;
        claims[0].token = allocationToken;
        claims[1].recipientId = recipient1Addr;
        claims[1].token = allocationToken;

        strategy.claimAllocation(abi.encode(claims));

        assertEq(IERC20(allocationToken).balanceOf(recipient0Addr), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1Addr), 25);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainDisabledClaim is IntegrationDonationVotingOffchainBase {
    function test_claim() public {
        // Claim allocation funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(recipient0Addr);

        DonationVotingOffchain.Claim[] memory claims = new DonationVotingOffchain.Claim[](2);
        claims[0].recipientId = recipient0Addr;
        claims[0].token = allocationToken;
        claims[1].recipientId = recipient1Addr;
        claims[1].token = allocationToken;

        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);
        strategyWithDirectTransfers.claimAllocation(abi.encode(claims));

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainSetPayout is IntegrationDonationVotingOffchainBase {
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

    function test_setPayout() public {
        vm.warp(allocationEndTime + 1);

        vm.startPrank(userAddr);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = POOL_AMOUNT * 1 / 4;
        amounts[1] = POOL_AMOUNT * 3 / 4;

        strategy.setPayout(abi.encode(recipients, amounts));

        (address recipientAddress, uint256 amount) = strategy.payoutSummaries(recipient0Addr);
        assertEq(amount, amounts[0]);
        assertEq(recipientAddress, recipient0Addr);

        (recipientAddress, amount) = strategy.payoutSummaries(recipient1Addr);
        assertEq(amount, amounts[1]);
        assertEq(recipientAddress, recipient1Addr);

        // Reverts
        vm.expectRevert(abi.encodeWithSelector(DonationVotingOffchain.PAYOUT_ALREADY_SET.selector, recipient0Addr));
        strategy.setPayout(abi.encode(recipients, amounts));

        recipients[0] = recipient2Addr;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.setPayout(abi.encode(recipients, amounts));

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainDistribute is IntegrationDonationVotingOffchainBase {
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

        // Set payouts
        vm.warp(allocationEndTime + 1);
        vm.startPrank(userAddr);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = POOL_AMOUNT * 1 / 4;
        amounts[1] = POOL_AMOUNT - POOL_AMOUNT * 1 / 4;

        strategy.setPayout(abi.encode(recipients, amounts));
        vm.stopPrank();
    }

    function test_distribute() public {
        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        vm.startPrank(address(allo));

        strategy.distribute(recipients, "", recipient2Addr);

        assertEq(IERC20(DAI).balanceOf(recipient0Addr), POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(recipient1Addr), POOL_AMOUNT - POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), 0);
        assertEq(strategy.getPoolAmount(), 0);

        vm.expectRevert(abi.encodeWithSelector(DonationVotingOffchain.NOTHING_TO_DISTRIBUTE.selector, recipient0Addr));
        strategy.distribute(recipients, "", recipient2Addr);

        recipients[0] = recipient2Addr;
        vm.expectRevert(abi.encodeWithSelector(DonationVotingOffchain.NOTHING_TO_DISTRIBUTE.selector, recipient2Addr));

        strategy.distribute(recipients, "", recipient2Addr);
    }
}
