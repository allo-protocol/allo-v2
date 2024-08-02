// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {IBiconomyForwarder} from "./IBiconomyForwarder.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract IntegrationAllo is Test {
    using ECDSA for bytes32;

    Allo public allo;
    Registry public registry;
    DonationVotingMerkleDistributionDirectTransferStrategy public strategy;

    address public owner;
    address public relayer;
    address public treasury;
    address public userAddr;

    address public recipient0Addr;
    address public recipient1Addr;
    address public recipient2Addr;

    uint256 public userPk;
    uint256 public recipient0Pk;
    uint256 public recipient1Pk;
    uint256 public recipient2Pk;

    bytes32 public profileId;

    address public constant biconomyForwarder = 0x84a0856b038eaAd1cC7E297cF34A7e72685A8693;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice Biconomy Forwarder separator
    bytes32 public constant domainSeparator = 0x4fde6db5140ab711910b567033f2d5e64dc4f7123d722004dd748edf6ed07abb;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20289932);

        owner = makeAddr("owner");
        treasury = makeAddr("treasury");

        (userAddr, userPk) = makeAddrAndKey("user");
        (recipient0Addr, recipient0Pk) = makeAddrAndKey("recipient0");
        (recipient1Addr, recipient1Pk) = makeAddrAndKey("recipient1");
        (recipient2Addr, recipient2Pk) = makeAddrAndKey("recipient2");

        allo = new Allo();
        registry = new Registry();
        strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(
            address(allo), "Test Strategy", ISignatureTransfer(address(1))
        );

        allo.initialize(owner, address(registry), payable(treasury), 0, 0, biconomyForwarder);
        registry.initialize(owner);

        vm.prank(userAddr);
        profileId =
            registry.createProfile(0, "Test Profile", Metadata({protocol: 1, pointer: ""}), userAddr, new address[](0));

        // Deal 130k DAI to the user
        deal(dai, userAddr, 130_000 ether);
    }

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

    /// @dev Send a transaction using the Biconomy Forwarder
    function _sendWithRelayer(address _from, address _to, bytes memory _data, uint256 _userPk)
        internal
        returns (bool _success, bytes memory _returnData)
    {
        // User signs the request
        IBiconomyForwarder.ERC20ForwardRequest memory req = IBiconomyForwarder.ERC20ForwardRequest({
            from: _from,
            to: _to,
            token: address(0),
            txGas: 500_000,
            tokenGasPrice: 0,
            batchId: 0,
            batchNonce: 0,
            deadline: block.timestamp + 1 days,
            data: _data
        });
        bytes32 structHash = keccak256(
            abi.encode(
                IBiconomyForwarder(biconomyForwarder).REQUEST_TYPEHASH(),
                req.from,
                req.to,
                req.token,
                req.txGas,
                req.tokenGasPrice,
                req.batchId,
                IBiconomyForwarder(biconomyForwarder).getNonce(req.from, req.batchId),
                req.deadline,
                keccak256(req.data)
            )
        );
        bytes32 digest = domainSeparator.toTypedDataHash(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_userPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Relayer submits the request
        vm.prank(relayer);
        (_success, _returnData) = IBiconomyForwarder(biconomyForwarder).executeEIP712(req, domainSeparator, sig);
        assertTrue(_success);
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
        _allowedTokens[0] = dai;

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
                dai,
                0,
                Metadata({protocol: 1, pointer: ""}),
                new address[](0)
            ),
            userPk
        );

        uint256 poolId = abi.decode(ret, (uint256));
        assertTrue(allo.isPoolAdmin(poolId, userAddr));
        assertFalse(allo.isPoolAdmin(poolId, relayer));

        DonationVotingMerkleDistributionDirectTransferStrategy deployedStrategy =
            DonationVotingMerkleDistributionDirectTransferStrategy(payable(address(allo.getPool(poolId).strategy)));

        // Fund pool
        vm.prank(userAddr);
        IERC20(dai).approve(address(allo), 100_000 ether);

        _sendWithRelayer(
            userAddr, address(allo), abi.encodeWithSelector(allo.fundPool.selector, poolId, 100_000 ether), userPk
        );
        assertTrue(IERC20(dai).balanceOf(address(allo.getPool(poolId).strategy)) == 100_000 ether);
        assertTrue(IERC20(dai).balanceOf(userAddr) == 30_000 ether);

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
        IERC20(dai).approve(address(deployedStrategy), 30_000 ether);

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
                            permitted: ISignatureTransfer.TokenPermissions({token: dai, amount: 10_000 ether}),
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
                            permitted: ISignatureTransfer.TokenPermissions({token: dai, amount: 10_000 ether}),
                            nonce: 0,
                            deadline: 0
                        }),
                        signature: new bytes(0)
                    })
                )
            ),
            userPk
        );
        assertTrue(IERC20(dai).balanceOf(address(deployedStrategy)) == 100_000 ether);
        assertTrue(IERC20(dai).balanceOf(userAddr) == 10_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient0Addr) == 10_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient1Addr) == 10_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient2Addr) == 0 ether);

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
        assertTrue(IERC20(dai).balanceOf(address(deployedStrategy)) == 10_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient0Addr) == 35_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient1Addr) == 40_000 ether);
        assertTrue(IERC20(dai).balanceOf(recipient2Addr) == 35_000 ether);
    }

    /// @dev Test the full flow:
    /// - creating a pool
    /// - fundPool
    /// - register recipients
    /// - allocate
    /// - distribute
    function test_fullFlow() public {
        //
    }
}
