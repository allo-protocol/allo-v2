// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {
    DonationVotingMerkleDistribution,
    DonationVotingOffchain
} from "contracts/strategies/DonationVotingMerkleDistribution.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntegrationDonationVotingMerkleDistributionBase is Test {
    address internal constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 internal constant POOL_AMOUNT = 1000;

    Allo internal allo;
    Registry internal registry;
    DonationVotingMerkleDistribution internal strategy;
    DonationVotingMerkleDistribution internal strategyWithDirectTransfers;

    address internal allocationToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    address internal owner;
    address internal treasury;
    address internal profileOwner;
    address internal recipient0;
    address internal recipient1;
    address internal recipient2;
    address internal allocator0;
    address internal allocator1;

    bytes32 internal profileId;

    uint256 internal poolId;

    uint64 internal registrationStartTime;
    uint64 internal registrationEndTime;
    uint64 internal allocationStartTime;
    uint64 internal allocationEndTime;
    uint64 internal withdrawalCooldown = 1 days;

    function _getApplicationStatus(address _recipientId, uint256 _status)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        IRecipientsExtension.Recipient memory recipient = strategy.getRecipient(_recipientId);
        uint256 recipientIndex = uint256(recipient.statusIndex) - 1;

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
        IRecipientsExtension.Recipient memory recipient = strategy.getRecipient(_recipientIds[0]);
        uint256 recipientIndex = uint256(recipient.statusIndex) - 1;
        uint256 rowIndex = recipientIndex / 64;
        uint256 statusRow = strategy.statusesBitMap(rowIndex);
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            recipient = strategy.getRecipient(_recipientIds[i]);
            recipientIndex = uint256(recipient.statusIndex) - 1;
            require(rowIndex == recipientIndex / 64, "_recipientIds belong to different rows");
            uint256 colIndex = (recipientIndex % 64) * 4;
            uint256 newRow = statusRow & ~(15 << colIndex);
            statusRow = newRow | (_statuses[i] << colIndex);
        }

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

    function setUp() public virtual {
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
        strategy = new DonationVotingMerkleDistribution(address(allo), false);
        strategyWithDirectTransfers = new DonationVotingMerkleDistribution(address(allo), true);

        // Initialize contracts
        // NOTE: trusted forwarder is not used
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1));
        registry.initialize(owner);

        // Creating profile
        vm.startPrank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Deal
        deal(DAI, profileOwner, POOL_AMOUNT * 2);
        IERC20(DAI).approve(address(allo), POOL_AMOUNT * 2);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = profileOwner;

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
                allowedTokens
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

        recipients[0] = recipient0;
        uint256 proposalBid = 10;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient0);
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient0);

        recipients[0] = recipient1;
        proposalBid = 20;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient1);
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient1);

        recipients[0] = recipient2;
        proposalBid = 30;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), abi.encode(uint256(proposalBid)));
        strategy.register(recipients, abi.encode(data), recipient2);
        strategyWithDirectTransfers.register(recipients, abi.encode(data), recipient2);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionReviewRecipients is
    IntegrationDonationVotingMerkleDistributionBase
{
    function test_reviewRecipients() public {
        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        uint256 recipientsCounter = strategy.recipientsCounter();

        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Revert if the registration period has finished
        vm.warp(registrationEndTime + 1);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Rejected);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);
        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionTimestamps is IntegrationDonationVotingMerkleDistributionBase {
    function test_updateTimestamps() public {
        vm.warp(registrationStartTime - 1 days);

        // Review recipients
        vm.startPrank(profileOwner);

        vm.expectRevert(DonationVotingOffchain.INVALID_TIMESTAMPS.selector);
        // allocationStartTime > allocationEndTime
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationEndTime, allocationStartTime
        );

        vm.expectRevert(DonationVotingOffchain.INVALID_TIMESTAMPS.selector);
        // _registrationStartTime > _registrationEndTime
        strategy.updatePoolTimestamps(
            registrationEndTime, registrationStartTime, allocationStartTime, allocationEndTime
        );

        vm.expectRevert(DonationVotingOffchain.INVALID_TIMESTAMPS.selector);
        // _registrationStartTime > allocationStartTime
        strategy.updatePoolTimestamps(
            allocationStartTime + 1, allocationEndTime, allocationStartTime, allocationEndTime
        );

        vm.expectRevert(DonationVotingOffchain.INVALID_TIMESTAMPS.selector);
        // _registrationEndTime > allocationEndTime
        strategy.updatePoolTimestamps(
            registrationStartTime, allocationEndTime + 1, allocationStartTime, allocationEndTime
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(DonationVotingOffchain.INVALID_TIMESTAMPS.selector);
        // block.timestamp > _registrationStartTime
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime
        );

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionAllocateERC20 is IntegrationDonationVotingMerkleDistributionBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

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
        recipients[0] = recipient0;
        recipients[1] = recipient1;

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

        recipients[0] = recipient2;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionAllocateETH is IntegrationDonationVotingMerkleDistributionBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

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
        recipients[0] = recipient0;
        recipients[1] = recipient1;

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

        recipients[0] = recipient2;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionDirectAllocateERC20 is
    IntegrationDonationVotingMerkleDistributionBase
{
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

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
        recipients[0] = recipient0;
        recipients[1] = recipient1;

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
        assertEq(IERC20(allocationToken).balanceOf(recipient0), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1), 25);

        uint256 amountAllocated0 = strategyWithDirectTransfers.amountAllocated(recipient0, allocationToken);
        uint256 amountAllocated1 = strategyWithDirectTransfers.amountAllocated(recipient0, allocationToken);
        assertEq(amountAllocated0, 0);
        assertEq(amountAllocated1, 0);

        recipients[0] = recipient2;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategyWithDirectTransfers.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionDirectAllocateETH is
    IntegrationDonationVotingMerkleDistributionBase
{
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

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
        recipients[0] = recipient0;
        recipients[1] = recipient1;

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
        assertEq(recipient1.balance, 25);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategyWithDirectTransfers)), 0);
        assertEq(IERC20(allocationToken).balanceOf(recipient0), 4);

        recipients[0] = recipient2;
        vm.expectRevert(Errors.RECIPIENT_NOT_ACCEPTED.selector);
        strategyWithDirectTransfers.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionClaim is IntegrationDonationVotingMerkleDistributionBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();

        vm.warp(allocationStartTime);
        deal(allocationToken, allocator0, 4 + 25);
        vm.startPrank(allocator0);
        IERC20(allocationToken).approve(address(strategy), 4 + 25);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

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

        vm.startPrank(recipient0);

        DonationVotingMerkleDistribution.Claim[] memory claims = new DonationVotingMerkleDistribution.Claim[](2);
        claims[0].recipientId = recipient0;
        claims[0].token = allocationToken;
        claims[1].recipientId = recipient1;
        claims[1].token = allocationToken;

        strategy.claimAllocation(abi.encode(claims));

        assertEq(IERC20(allocationToken).balanceOf(recipient0), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1), 25);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionDisabledClaim is IntegrationDonationVotingMerkleDistributionBase {
    function test_claim() public {
        // Claim allocation funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(recipient0);

        DonationVotingMerkleDistribution.Claim[] memory claims = new DonationVotingMerkleDistribution.Claim[](2);
        claims[0].recipientId = recipient0;
        claims[0].token = allocationToken;
        claims[1].recipientId = recipient1;
        claims[1].token = allocationToken;

        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);
        strategyWithDirectTransfers.claimAllocation(abi.encode(claims));

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionSetPayout is IntegrationDonationVotingMerkleDistributionBase {
    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        vm.stopPrank();
    }

    function test_setPayout() public {
        vm.warp(allocationEndTime + 1);

        vm.startPrank(profileOwner);

        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory distributionMetadata = Metadata({protocol: 1, pointer: "A"});
        strategy.setPayout(abi.encode(merkleRoot, distributionMetadata));

        (uint256 protocol, string memory pointer) = strategy.distributionMetadata();
        assertEq(strategy.merkleRoot(), merkleRoot);
        assertEq(protocol, 1);
        assertEq(pointer, "A");

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingMerkleDistributionDistribute is IntegrationDonationVotingMerkleDistributionBase {
    DonationVotingMerkleDistribution.Distribution[] internal _distributions;
    bytes32 internal _merkleRoot;

    function setUp() public override {
        super.setUp();

        // Review recipients
        vm.startPrank(profileOwner);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        address[] memory _recipientIds = new address[](2);
        uint256[] memory _newStatuses = new uint256[](2);

        // Set accepted recipients
        _recipientIds[0] = recipient0;
        _recipientIds[1] = recipient1;
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses);

        uint256 recipientsCounter = strategy.recipientsCounter();
        strategy.reviewRecipients(statuses, recipientsCounter);

        // Set payouts
        vm.warp(allocationEndTime + 1);
        vm.startPrank(profileOwner);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = POOL_AMOUNT * 1 / 4;
        amounts[1] = POOL_AMOUNT - POOL_AMOUNT * 1 / 4;

        (bytes32 merkleRoot, DonationVotingMerkleDistribution.Distribution[] memory distributions) =
            _getMerkleRootAndDistributions(recipients, amounts);
        _distributions.push(distributions[0]);
        _distributions.push(distributions[1]);
        Metadata memory distributionMetadata = Metadata({protocol: 1, pointer: "A"});
        strategy.setPayout(abi.encode(merkleRoot, distributionMetadata));
        vm.stopPrank();
    }

    function test_distribute() public {
        address[] memory recipients = new address[](0);

        vm.startPrank(address(allo));

        bytes memory data = abi.encode(_distributions);
        strategy.distribute(recipients, data, recipient2);

        assertEq(IERC20(DAI).balanceOf(recipient0), POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(recipient1), POOL_AMOUNT - POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), 0);
        assertEq(strategy.getPoolAmount(), 0);

        vm.expectRevert(abi.encodeWithSelector(DonationVotingMerkleDistribution.ALREADY_DISTRIBUTED.selector, 0));
        strategy.distribute(recipients, data, recipient2);

        vm.startPrank(address(profileOwner));
        vm.expectRevert(DonationVotingMerkleDistribution.DISTRIBUTION_ALREADY_STARTED.selector);
        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory distributionMetadata = Metadata({protocol: 1, pointer: "A"});
        strategy.setPayout(abi.encode(merkleRoot, distributionMetadata));
    }

    function _getMerkleRootAndDistributions(address[] memory _recipientIds, uint256[] memory _amounts)
        internal
        pure
        returns (bytes32, DonationVotingMerkleDistribution.Distribution[] memory)
    {
        DonationVotingMerkleDistribution.Distribution[] memory distributions =
            new DonationVotingMerkleDistribution.Distribution[](2);

        DonationVotingMerkleDistribution.Distribution memory distribution0 = DonationVotingMerkleDistribution
            .Distribution({index: 0, recipientId: _recipientIds[0], amount: _amounts[0], merkleProof: new bytes32[](1)});
        bytes32 node0 = keccak256(abi.encode(distribution0.index, distribution0.recipientId, distribution0.amount));

        DonationVotingMerkleDistribution.Distribution memory distribution1 = DonationVotingMerkleDistribution
            .Distribution({index: 1, recipientId: _recipientIds[1], amount: _amounts[1], merkleProof: new bytes32[](1)});
        bytes32 node1 = keccak256(abi.encode(distribution1.index, distribution1.recipientId, distribution1.amount));

        distribution0.merkleProof[0] = node1;
        distribution1.merkleProof[0] = node0;

        distributions[0] = distribution0;
        distributions[1] = distribution1;

        bytes32 merkleRoot = _hashPair(node1, node0);

        return (merkleRoot, distributions);
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encode(a, b)) : keccak256(abi.encode(b, a));
    }
}
