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

    uint256 public userPk;

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

        // Deal 100k DAI to the user
        deal(dai, userAddr, 100_000 ether);
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
    /// - allocate
    /// - distribute
    function test_fullFlowWithMetaTx() public {
        // Create pool
        bytes memory _initStrategyData = abi.encode(
            DonationVotingMerkleDistributionBaseStrategy.InitializeData({
                useRegistryAnchor: false,
                metadataRequired: false,
                registrationStartTime: uint64(block.timestamp),
                registrationEndTime: uint64(block.timestamp + 7 days),
                allocationStartTime: uint64(block.timestamp),
                allocationEndTime: uint64(block.timestamp + 7 days),
                allowedTokens: new address[](0)
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

        // Fund pool
        vm.prank(userAddr);
        IERC20(dai).approve(address(allo), 100_000 ether);

        (, ret) = _sendWithRelayer(
            userAddr, address(allo), abi.encodeWithSelector(allo.fundPool.selector, poolId, 100_000 ether), userPk
        );
        assertTrue(IERC20(dai).balanceOf(address(allo.getPool(poolId).strategy)) == 100_000 ether);
        assertTrue(IERC20(dai).balanceOf(userAddr) == 0);

        // Allocate
        // TODO
    }

    /// @dev Test the full flow:
    /// - creating a pool
    /// - fundPool
    /// - allocate
    /// - distribute
    function test_fullFlow() public {
        //
    }
}
