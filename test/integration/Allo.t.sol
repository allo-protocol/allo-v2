// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DonationVotingOffchain} from "strategies/examples/donation-voting/DonationVotingOffchain.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationAllo is IntegrationBase {
    IAllo public allo;
    DonationVotingOffchain public strategy;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        strategy = new DonationVotingOffchain(ALLO_PROXY, "DonationVotingOffchain", false);

        // Deal 130k DAI to the user
        deal(DAI, userAddr, 130_000 ether);
    }

    /// @dev Test the full flow, using meta-tx when possible:
    /// - creating a pool
    /// - fundPool
    /// - register recipients
    /// - allocate
    /// - distribute
    function test_fullFlowWithMetaTx() public {
        // Create pool
        address[] memory _allowedTokens = new address[](1);
        _allowedTokens[0] = DAI;

        bytes memory _initStrategyData = abi.encode(
            IRecipientsExtension.RecipientInitializeData({
                metadataRequired: false,
                registrationStartTime: uint64(block.timestamp),
                registrationEndTime: uint64(block.timestamp + 7 days)
            }),
            uint64(block.timestamp),
            uint64(block.timestamp + 7 days),
            0,
            _allowedTokens
        );

        (, bytes memory ret) = _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(
                allo.createPool.selector,
                profileId,
                address(strategy),
                _initStrategyData,
                DAI,
                0,
                Metadata({protocol: 1, pointer: ""}),
                new address[](0)
            ),
            userPk
        );

        uint256 poolId = abi.decode(ret, (uint256));
        // userAddr is the admin of the pool
        assertTrue(allo.isPoolAdmin(poolId, userAddr));

        DonationVotingOffchain deployedStrategy =
            DonationVotingOffchain(payable(address(allo.getPool(poolId).strategy)));

        // Fund pool
        vm.prank(userAddr);
        IERC20(DAI).approve(address(allo), 100_000 ether);

        _sendWithRelayer(
            userAddr, address(allo), abi.encodeWithSelector(allo.fundPool.selector, poolId, 100_000 ether), userPk
        );
        // userAddr transferred 100k DAI to the pool
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 30_000 ether);

        // Register recipients
        address[] memory recipients = new address[](1);
        bytes[] memory datas = new bytes[](1);

        recipients[0] = recipient0Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        _sendWithRelayer(
            recipient0Addr,
            address(allo),
            abi.encodeWithSelector(allo.registerRecipient.selector, poolId, recipients, abi.encode(datas)),
            recipient0Pk
        );

        recipients[0] = recipient1Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        _sendWithRelayer(
            recipient1Addr,
            address(allo),
            abi.encodeWithSelector(allo.registerRecipient.selector, poolId, recipients, abi.encode(datas)),
            recipient1Pk
        );

        recipients[0] = recipient2Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        _sendWithRelayer(
            recipient2Addr,
            address(allo),
            abi.encodeWithSelector(allo.registerRecipient.selector, poolId, recipients, abi.encode(datas)),
            recipient2Pk
        );
        // Recipients are registered
        assertTrue(deployedStrategy.getRecipient(recipient0Addr).recipientAddress == recipient0Addr);
        assertTrue(deployedStrategy.getRecipient(recipient1Addr).recipientAddress == recipient1Addr);
        assertTrue(deployedStrategy.getRecipient(recipient2Addr).recipientAddress == recipient2Addr);

        // Review recipient (it's needed to allocate)
        vm.startPrank(userAddr);

        // TODO: make them in batch
        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient1Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient2Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        vm.stopPrank();

        // Allocate
        vm.prank(userAddr);
        IERC20(DAI).approve(address(deployedStrategy), 30_000 ether);

        address[] memory _recipients = new address[](1);
        uint256[] memory _amounts = new uint256[](1);
        address[] memory _tokens = new address[](1);
        bytes[] memory _permits = new bytes[](1);
        _tokens[0] = DAI;
        _amounts[0] = 10_000 ether;

        _recipients[0] = recipient0Addr;
        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(allo.allocate.selector, poolId, _recipients, _amounts, abi.encode(_tokens, _permits)),
            userPk
        );

        _recipients[0] = recipient1Addr;
        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(allo.allocate.selector, poolId, _recipients, _amounts, abi.encode(_tokens, _permits)),
            userPk
        );
        // Strategy still has 120k DAI, userAddr has 10k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 120_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 10_000 ether);
        // Recipients have 0 DAI
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 0 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 0 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 0 ether);

        // Move time after allocation end time
        vm.warp(block.timestamp + 8 days);

        address[] memory _recipientsToDistribute = new address[](3);
        _recipientsToDistribute[0] = recipient0Addr;
        _recipientsToDistribute[1] = recipient1Addr;
        _recipientsToDistribute[2] = recipient2Addr;

        uint256[] memory _amountsToDistribute = new uint256[](3);
        _amountsToDistribute[0] = 25_000 ether;
        _amountsToDistribute[1] = 30_000 ether;
        _amountsToDistribute[2] = 35_000 ether;

        // Set payout (it's needed to distribute)
        vm.prank(userAddr);
        deployedStrategy.setPayout(abi.encode(_recipientsToDistribute, _amountsToDistribute));

        // Distribute
        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(allo.distribute.selector, poolId, _recipientsToDistribute, bytes("")),
            userPk
        );

        // After distribution, the strategy has 10k DAI, recipients have 25k, 30k, and 35k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 30_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 25_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 30_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 35_000 ether);
    }

    /// @dev Test the full flow:
    /// - creating a pool
    /// - fundPool
    /// - register recipients
    /// - allocate
    /// - distribute
    function test_fullFlow() public {
        // Create pool
        address[] memory _allowedTokens = new address[](1);
        _allowedTokens[0] = DAI;

        bytes memory _initStrategyData = abi.encode(
            IRecipientsExtension.RecipientInitializeData({
                metadataRequired: false,
                registrationStartTime: uint64(block.timestamp),
                registrationEndTime: uint64(block.timestamp + 7 days)
            }),
            uint64(block.timestamp),
            uint64(block.timestamp + 7 days),
            0,
            _allowedTokens
        );

        vm.startPrank(userAddr);
        uint256 poolId = allo.createPool(
            profileId,
            address(strategy),
            _initStrategyData,
            DAI,
            0,
            Metadata({protocol: 1, pointer: ""}),
            new address[](0)
        );

        // userAddr is the admin of the pool
        assertTrue(allo.isPoolAdmin(poolId, userAddr));

        DonationVotingOffchain deployedStrategy =
            DonationVotingOffchain(payable(address(allo.getPool(poolId).strategy)));

        // Fund pool
        IERC20(DAI).approve(address(allo), 100_000 ether);
        allo.fundPool(poolId, 100_000 ether);

        // userAddr transferred 100k DAI to the pool
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 30_000 ether);

        vm.stopPrank();

        // Register recipients
        address[] memory recipients = new address[](1);
        bytes[] memory datas = new bytes[](1);

        recipients[0] = recipient0Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        vm.prank(recipient0Addr);
        allo.registerRecipient(poolId, recipients, abi.encode(datas));

        recipients[0] = recipient1Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        vm.prank(recipient1Addr);
        allo.registerRecipient(poolId, recipients, abi.encode(datas));

        recipients[0] = recipient2Addr;
        datas[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        vm.prank(recipient2Addr);
        allo.registerRecipient(poolId, recipients, abi.encode(datas));

        // Recipients are registered
        assertTrue(deployedStrategy.getRecipient(recipient0Addr).recipientAddress == recipient0Addr);
        assertTrue(deployedStrategy.getRecipient(recipient1Addr).recipientAddress == recipient1Addr);
        assertTrue(deployedStrategy.getRecipient(recipient2Addr).recipientAddress == recipient2Addr);

        // Review recipient (it's needed to allocate)
        vm.startPrank(userAddr);

        // TODO: make them in batch
        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient1Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient2Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        // Allocate
        IERC20(DAI).approve(address(deployedStrategy), 30_000 ether);

        address[] memory _recipients = new address[](1);
        uint256[] memory _amounts = new uint256[](1);
        address[] memory _tokens = new address[](1);
        bytes[] memory _permits = new bytes[](1);
        _tokens[0] = DAI;
        _amounts[0] = 10_000 ether;

        _recipients[0] = recipient0Addr;
        allo.allocate(poolId, _recipients, _amounts, abi.encode(_tokens, _permits));

        _recipients[0] = recipient1Addr;
        allo.allocate(poolId, _recipients, _amounts, abi.encode(_tokens, _permits));
        // Strategy still has 120k DAI, userAddr has 10k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 120_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 10_000 ether);
        // Recipients have 0 DAI
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 0 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 0 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 0 ether);

        // Move time after allocation end time
        vm.warp(block.timestamp + 8 days);

        address[] memory _recipientsToDistribute = new address[](3);
        _recipientsToDistribute[0] = recipient0Addr;
        _recipientsToDistribute[1] = recipient1Addr;
        _recipientsToDistribute[2] = recipient2Addr;

        uint256[] memory _amountsToDistribute = new uint256[](3);
        _amountsToDistribute[0] = 25_000 ether;
        _amountsToDistribute[1] = 30_000 ether;
        _amountsToDistribute[2] = 35_000 ether;

        // Set payout (it's needed to distribute)
        deployedStrategy.setPayout(abi.encode(_recipientsToDistribute, _amountsToDistribute));

        // Distribute
        allo.distribute(poolId, _recipientsToDistribute, bytes(""));

        // After distribution, the strategy has 10k DAI, recipients have 25k, 30k, and 35k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 30_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 25_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 30_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 35_000 ether);

        vm.stopPrank();
    }
}
