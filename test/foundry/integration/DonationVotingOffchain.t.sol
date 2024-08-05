// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {DonationVotingOffchain} from "contracts/strategies/DonationVotingOffchain.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntegrationDonationVotingOffchainBase is Test {
    address internal constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 internal constant POOL_AMOUNT = 1000;

    Allo internal allo;
    Registry internal registry;
    DonationVotingOffchain internal strategy;

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
        strategy = new DonationVotingOffchain(address(allo));

        // Initialize contracts
        // NOTE: trusted forwarder is not used
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1));
        registry.initialize(owner);

        // Creating profile
        vm.prank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Deal
        deal(DAI, profileOwner, POOL_AMOUNT);
        vm.prank(profileOwner);
        IERC20(DAI).approve(address(allo), POOL_AMOUNT);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = profileOwner;
        vm.prank(profileOwner);

        registrationStartTime = uint64(block.timestamp);
        registrationEndTime = uint64(block.timestamp + 7 days);
        allocationStartTime = uint64(block.timestamp + 7 days + 1);
        allocationEndTime = uint64(block.timestamp + 10 days);
        address[] memory allowedTokens = new address[](0);
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

        // Adding recipients
        vm.startPrank(address(allo));

        address[] memory recipients = new address[](1);
        bytes[] memory data = new bytes[](1);

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
}

contract IntegrationDonationVotingOffchainReviewRecipients is IntegrationDonationVotingOffchainBase {
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

contract IntegrationDonationVotingOffchainTimestamps is IntegrationDonationVotingOffchainBase {
    function test_updateTimestamps() public {
        vm.warp(registrationStartTime - 1 days);

        // Review recipients
        vm.startPrank(profileOwner);

        vm.expectRevert(Errors.INVALID.selector);
        // allocationStartTime > allocationEndTime
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationEndTime, allocationStartTime
        );

        vm.expectRevert(Errors.INVALID.selector);
        // _registrationStartTime > _registrationEndTime
        strategy.updatePoolTimestamps(
            registrationEndTime, registrationStartTime, allocationStartTime, allocationEndTime
        );

        vm.expectRevert(Errors.INVALID.selector);
        // _registrationStartTime > allocationStartTime
        strategy.updatePoolTimestamps(
            allocationStartTime + 1, allocationEndTime, allocationStartTime, allocationEndTime
        );

        vm.expectRevert(Errors.INVALID.selector);
        // _registrationEndTime > allocationEndTime
        strategy.updatePoolTimestamps(
            registrationStartTime, allocationEndTime + 1, allocationStartTime, allocationEndTime
        );

        vm.warp(registrationStartTime + 1);
        vm.expectRevert(Errors.INVALID.selector);
        // block.timestamp > _registrationStartTime
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime
        );

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainAllocateERC20 is IntegrationDonationVotingOffchainBase {
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
        bytes memory data = abi.encode(tokens);

        vm.startPrank(address(allo));

        strategy.allocate(recipients, amounts, data, allocator0);

        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 4 + 25);

        recipients[0] = recipient2;
        vm.expectRevert(abi.encodeWithSelector(Errors.RECIPIENT_ERROR.selector, recipient2));
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainAllocateETH is IntegrationDonationVotingOffchainBase {
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
        bytes memory data = abi.encode(tokens);

        strategy.allocate{value: 25}(recipients, amounts, data, allocator0);

        assertEq(allocator0.balance, 0);
        assertEq(address(strategy).balance, 25);
        assertEq(IERC20(allocationToken).balanceOf(allocator0), 0);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 4);

        recipients[0] = recipient2;
        vm.expectRevert(abi.encodeWithSelector(Errors.RECIPIENT_ERROR.selector, recipient2));
        strategy.allocate(recipients, amounts, data, allocator0);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainClaim is IntegrationDonationVotingOffchainBase {
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
        bytes memory data = abi.encode(tokens);

        vm.startPrank(address(allo));
        strategy.allocate(recipients, amounts, data, allocator0);
        vm.stopPrank();
    }

    function test_claim() public {
        // Claim allocation funds
        vm.warp(allocationEndTime + 1);

        vm.startPrank(recipient0);

        DonationVotingOffchain.Claim[] memory claims = new DonationVotingOffchain.Claim[](2);
        claims[0].recipientId = recipient0;
        claims[0].token = allocationToken;
        claims[1].recipientId = recipient1;
        claims[1].token = allocationToken;

        strategy.claimAllocation(claims);

        assertEq(IERC20(allocationToken).balanceOf(recipient0), 4);
        assertEq(IERC20(allocationToken).balanceOf(recipient1), 25);
        assertEq(IERC20(allocationToken).balanceOf(address(strategy)), 0);

        vm.expectRevert(Errors.INVALID.selector);
        strategy.claimAllocation(claims);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainSetPayout is IntegrationDonationVotingOffchainBase {
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

        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = POOL_AMOUNT * 1 / 4;
        amounts[1] = POOL_AMOUNT * 3 / 4;

        strategy.setPayout(recipients, amounts);

        (address recipientAddress, uint256 amount) = strategy.payoutSummaries(recipient0);
        assertEq(amount, amounts[0]);
        assertEq(recipientAddress, recipient0);

        (recipientAddress, amount) = strategy.payoutSummaries(recipient1);
        assertEq(amount, amounts[1]);
        assertEq(recipientAddress, recipient1);

        // Reverts
        vm.expectRevert(abi.encodeWithSelector(Errors.RECIPIENT_ERROR.selector, recipient0));
        strategy.setPayout(recipients, amounts);

        recipients[0] = recipient2;
        vm.expectRevert(abi.encodeWithSelector(Errors.RECIPIENT_ERROR.selector, recipient2));
        strategy.setPayout(recipients, amounts);

        vm.stopPrank();
    }
}

contract IntegrationDonationVotingOffchainDistribute is IntegrationDonationVotingOffchainBase {
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

        strategy.setPayout(recipients, amounts);
        vm.stopPrank();
    }

    function test_distribute() public {
        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

        vm.startPrank(address(allo));

        strategy.distribute(recipients, "", recipient2);

        assertEq(IERC20(DAI).balanceOf(recipient0), POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(recipient1), POOL_AMOUNT - POOL_AMOUNT * 1 / 4);
        assertEq(IERC20(DAI).balanceOf(address(strategy)), 0);
        assertEq(strategy.getPoolAmount(), 0);

        vm.expectRevert(Errors.INVALID.selector);
        strategy.distribute(recipients, "", recipient2);

        recipients[0] = recipient2;
        vm.expectRevert(Errors.INVALID.selector);
        strategy.distribute(recipients, "", recipient2);
    }
}
