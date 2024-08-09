// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IntegrationBase} from "./IntegrationBase.sol";

contract IntegrationAllo is IntegrationBase {
    IAllo public allo;
    DonationVotingMerkleDistributionDirectTransferStrategy public strategy;

    // TODO: once other strategies are implemented, move this to the base contract
    // Also, use IRecipientsExtension instead of the DonationVotingMerkleDistributionBaseStrategy
    function _getApplicationStatus(address _recipientId, uint256 _status, address payable _strategy)
        internal
        view
        returns (DonationVotingMerkleDistributionDirectTransferStrategy.ApplicationStatus memory)
    {
        uint256 recipientIndex =
            DonationVotingMerkleDistributionBaseStrategy(_strategy).recipientToStatusIndexes(_recipientId) - 1;

        uint256 rowIndex = recipientIndex / 64;
        uint256 colIndex = (recipientIndex % 64) * 4;
        uint256 currentRow = DonationVotingMerkleDistributionBaseStrategy(_strategy).statusesBitMap(rowIndex);
        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        return DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(
            ALLO_PROXY, "Test Strategy", ISignatureTransfer(address(1))
        );

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
            DonationVotingMerkleDistributionBaseStrategy.InitializeData({
                useRegistryAnchor: false,
                metadataRequired: false,
                registrationStartTime: uint64(block.timestamp),
                registrationEndTime: uint64(block.timestamp + 7 days),
                allocationStartTime: uint64(block.timestamp),
                allocationEndTime: uint64(block.timestamp + 7 days),
                allowedTokens: _allowedTokens
            })
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

        DonationVotingMerkleDistributionDirectTransferStrategy deployedStrategy =
            DonationVotingMerkleDistributionDirectTransferStrategy(payable(address(allo.getPool(poolId).strategy)));

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
        _sendWithRelayer(
            recipient0Addr,
            address(allo),
            abi.encodeWithSelector(
                allo.registerRecipient.selector,
                poolId,
                abi.encode(address(0), recipient0Addr, Metadata({protocol: 0, pointer: ""}))
            ),
            recipient0Pk
        );
        _sendWithRelayer(
            recipient1Addr,
            address(allo),
            abi.encodeWithSelector(
                allo.registerRecipient.selector,
                poolId,
                abi.encode(address(0), recipient1Addr, Metadata({protocol: 0, pointer: ""}))
            ),
            recipient1Pk
        );
        _sendWithRelayer(
            recipient2Addr,
            address(allo),
            abi.encodeWithSelector(
                allo.registerRecipient.selector,
                poolId,
                abi.encode(address(0), recipient2Addr, Metadata({protocol: 0, pointer: ""}))
            ),
            recipient2Pk
        );
        // Recipients are registered
        assertTrue(deployedStrategy.getRecipient(recipient0Addr).recipientAddress == recipient0Addr);
        assertTrue(deployedStrategy.getRecipient(recipient1Addr).recipientAddress == recipient1Addr);
        assertTrue(deployedStrategy.getRecipient(recipient2Addr).recipientAddress == recipient2Addr);

        // Review recipient (it's needed to allocate)
        vm.startPrank(userAddr);

        // TODO: make them in batch
        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
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

        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(
                allo.allocate.selector,
                poolId,
                abi.encode(
                    recipient0Addr,
                    DonationVotingMerkleDistributionBaseStrategy.PermitType.None,
                    DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
                        permit: ISignatureTransfer.PermitTransferFrom({
                            permitted: ISignatureTransfer.TokenPermissions({token: DAI, amount: 10_000 ether}),
                            nonce: 0,
                            deadline: 0
                        }),
                        signature: new bytes(0)
                    })
                )
            ),
            userPk
        );
        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(
                allo.allocate.selector,
                poolId,
                abi.encode(
                    recipient1Addr,
                    DonationVotingMerkleDistributionBaseStrategy.PermitType.None,
                    DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
                        permit: ISignatureTransfer.PermitTransferFrom({
                            permitted: ISignatureTransfer.TokenPermissions({token: DAI, amount: 10_000 ether}),
                            nonce: 0,
                            deadline: 0
                        }),
                        signature: new bytes(0)
                    })
                )
            ),
            userPk
        );
        // Strategy still has 100k DAI, userAddr has 10k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 10_000 ether);
        // Recipients 0 and 1 have 10k DAI each
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 10_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 10_000 ether);
        // Recipient 2 has 0 DAI
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 0 ether);

        // Move time after allocation end time
        vm.warp(block.timestamp + 8 days);

        // Update distribution
        vm.prank(userAddr);
        deployedStrategy.updateDistribution(
            bytes32(0xadafbadc26201df820cf1beaba9576038fc21a3a81e19534389dbc7280c97014),
            Metadata({protocol: 0, pointer: ""})
        );

        // Distribute
        DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory _distributions =
            new DonationVotingMerkleDistributionBaseStrategy.Distribution[](3);

        _distributions[0] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 0,
            recipientId: recipient0Addr,
            amount: 25_000 ether,
            merkleProof: new bytes32[](2)
        });
        _distributions[0].merkleProof[0] = bytes32(0x4a4054703db6c08f7627a4cce111a61cff80f28bab8545a9968779af1152ac33);
        _distributions[0].merkleProof[1] = bytes32(0x781f6f3993ddc773d04d8166adc14e50c7423289d4cd4a715b32f7f56410c411);

        _distributions[1] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 1,
            recipientId: recipient1Addr,
            amount: 30_000 ether,
            merkleProof: new bytes32[](2)
        });
        _distributions[1].merkleProof[0] = bytes32(0x40796454065a0d690bbf69ece420b5f54667e1eb5d9ae41c876484d416918659);
        _distributions[1].merkleProof[1] = bytes32(0x781f6f3993ddc773d04d8166adc14e50c7423289d4cd4a715b32f7f56410c411);

        _distributions[2] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 2,
            recipientId: recipient2Addr,
            amount: 35_000 ether,
            merkleProof: new bytes32[](1)
        });
        _distributions[2].merkleProof[0] = bytes32(0x7be035e1b55d42f33a6304d14dcd5e117980643375603ba676a4d8e29ae461ef);

        bytes memory _distributeData = abi.encode(_distributions);
        _sendWithRelayer(
            userAddr,
            address(allo),
            abi.encodeWithSelector(allo.distribute.selector, poolId, new address[](0), _distributeData),
            userPk
        );
        // After distribution, the strategy has 10k DAI, recipients have 35k, 40k, and 35k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 10_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 35_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 40_000 ether);
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
            DonationVotingMerkleDistributionBaseStrategy.InitializeData({
                useRegistryAnchor: false,
                metadataRequired: false,
                registrationStartTime: uint64(block.timestamp),
                registrationEndTime: uint64(block.timestamp + 7 days),
                allocationStartTime: uint64(block.timestamp),
                allocationEndTime: uint64(block.timestamp + 7 days),
                allowedTokens: _allowedTokens
            })
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

        DonationVotingMerkleDistributionDirectTransferStrategy deployedStrategy =
            DonationVotingMerkleDistributionDirectTransferStrategy(payable(address(allo.getPool(poolId).strategy)));

        // Fund pool
        IERC20(DAI).approve(address(allo), 100_000 ether);
        allo.fundPool(poolId, 100_000 ether);

        // userAddr transferred 100k DAI to the pool
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 30_000 ether);

        vm.stopPrank();

        // Register recipients
        vm.prank(recipient0Addr);
        allo.registerRecipient(poolId, abi.encode(address(0), recipient0Addr, Metadata({protocol: 0, pointer: ""})));

        vm.prank(recipient1Addr);
        allo.registerRecipient(poolId, abi.encode(address(0), recipient1Addr, Metadata({protocol: 0, pointer: ""})));

        vm.prank(recipient2Addr);
        allo.registerRecipient(poolId, abi.encode(address(0), recipient2Addr, Metadata({protocol: 0, pointer: ""})));
        // Recipients are registered
        assertTrue(deployedStrategy.getRecipient(recipient0Addr).recipientAddress == recipient0Addr);
        assertTrue(deployedStrategy.getRecipient(recipient1Addr).recipientAddress == recipient1Addr);
        assertTrue(deployedStrategy.getRecipient(recipient2Addr).recipientAddress == recipient2Addr);

        // Review recipient (it's needed to allocate)
        vm.startPrank(userAddr);

        // TODO: make them in batch
        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(recipient0Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient1Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        statuses[0] = _getApplicationStatus(recipient2Addr, 2, payable(address(deployedStrategy)));
        deployedStrategy.reviewRecipients(statuses, deployedStrategy.recipientsCounter());

        // Allocate
        IERC20(DAI).approve(address(deployedStrategy), 30_000 ether);

        allo.allocate(
            poolId,
            abi.encode(
                recipient0Addr,
                DonationVotingMerkleDistributionBaseStrategy.PermitType.None,
                DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
                    permit: ISignatureTransfer.PermitTransferFrom({
                        permitted: ISignatureTransfer.TokenPermissions({token: DAI, amount: 10_000 ether}),
                        nonce: 0,
                        deadline: 0
                    }),
                    signature: new bytes(0)
                })
            )
        );
        allo.allocate(
            poolId,
            abi.encode(
                recipient1Addr,
                DonationVotingMerkleDistributionBaseStrategy.PermitType.None,
                DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
                    permit: ISignatureTransfer.PermitTransferFrom({
                        permitted: ISignatureTransfer.TokenPermissions({token: DAI, amount: 10_000 ether}),
                        nonce: 0,
                        deadline: 0
                    }),
                    signature: new bytes(0)
                })
            )
        );
        // Strategy still has 100k DAI, userAddr has 10k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(DAI).balanceOf(userAddr) == 10_000 ether);
        // Recipients 0 and 1 have 10k DAI each
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 10_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 10_000 ether);
        // Recipient 2 has 0 DAI
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 0 ether);

        // Move time after allocation end time
        vm.warp(block.timestamp + 8 days);

        // Update distribution
        deployedStrategy.updateDistribution(
            bytes32(0xadafbadc26201df820cf1beaba9576038fc21a3a81e19534389dbc7280c97014),
            Metadata({protocol: 0, pointer: ""})
        );

        // Distribute
        DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory _distributions =
            new DonationVotingMerkleDistributionBaseStrategy.Distribution[](3);

        _distributions[0] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 0,
            recipientId: recipient0Addr,
            amount: 25_000 ether,
            merkleProof: new bytes32[](2)
        });
        _distributions[0].merkleProof[0] = bytes32(0x4a4054703db6c08f7627a4cce111a61cff80f28bab8545a9968779af1152ac33);
        _distributions[0].merkleProof[1] = bytes32(0x781f6f3993ddc773d04d8166adc14e50c7423289d4cd4a715b32f7f56410c411);

        _distributions[1] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 1,
            recipientId: recipient1Addr,
            amount: 30_000 ether,
            merkleProof: new bytes32[](2)
        });
        _distributions[1].merkleProof[0] = bytes32(0x40796454065a0d690bbf69ece420b5f54667e1eb5d9ae41c876484d416918659);
        _distributions[1].merkleProof[1] = bytes32(0x781f6f3993ddc773d04d8166adc14e50c7423289d4cd4a715b32f7f56410c411);

        _distributions[2] = DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 2,
            recipientId: recipient2Addr,
            amount: 35_000 ether,
            merkleProof: new bytes32[](1)
        });
        _distributions[2].merkleProof[0] = bytes32(0x7be035e1b55d42f33a6304d14dcd5e117980643375603ba676a4d8e29ae461ef);

        bytes memory _distributeData = abi.encode(_distributions);
        allo.distribute(poolId, new address[](0), _distributeData);

        // After distribution, the strategy has 10k DAI, recipients have 35k, 40k, and 35k DAI
        assertTrue(IERC20(DAI).balanceOf(address(deployedStrategy)) == 10_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient0Addr) == 35_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient1Addr) == 40_000 ether);
        assertTrue(IERC20(DAI).balanceOf(recipient2Addr) == 35_000 ether);

        vm.stopPrank();
    }
}
