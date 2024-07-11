// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry, Metadata} from "../../../contracts/core/Registry.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from "../../../contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {IBiconomyForwarder} from "./IBiconomyForwarder.sol";
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

contract IntegrationAllo is Test {
    struct InitializeData {
        bool useRegistryAnchor;
        bool metadataRequired;
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        address[] allowedTokens;
    }

    Allo public allo;
    Registry public registry;
    DonationVotingMerkleDistributionDirectTransferStrategy public strategy;

    address public owner;
    address public relayer;
    address public treasury;
    address public user;

    bytes32 public profileId;

    address public constant biconomyForwarder = 0x84a0856b038eaAd1cC7E297cF34A7e72685A8693;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('mainnet'));

        owner = makeAddr('owner');
        treasury = makeAddr('treasury');
        user = makeAddr('user');

        allo = new Allo();
        registry = new Registry();
        strategy = new DonationVotingMerkleDistributionDirectTransferStrategy(address(allo), "Test Strategy", ISignatureTransfer(address(1)));

        allo.initialize(
            owner,
            address(registry),
            payable(treasury),
            0,
            0,
            biconomyForwarder
        );

        registry.initialize(owner);

        vm.prank(user);
        profileId = registry.createProfile(0, "Test Profile", Metadata({
            protocol: 1,
            pointer: ''
        }), user, new address[](0));
    }

    function test_CreatePoolWithMetaTx() public {
        bytes memory _initStrategyData = abi.encode(InitializeData({
            useRegistryAnchor: false,
            metadataRequired: false,
            registrationStartTime: uint64(block.timestamp), 
            registrationEndTime: uint64(block.timestamp + 7 days),
            allocationStartTime: uint64(block.timestamp),
            allocationEndTime: uint64(block.timestamp + 7 days),
            allowedTokens: new address[](0)
        }));

        bytes32 domainSeparator = 0x4fde6db5140ab711910b567033f2d5e64dc4f7123d722004dd748edf6ed07abb; // Biconomy Forwarder

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x00, '');
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(relayer);
        IBiconomyForwarder(biconomyForwarder).executeEIP712(
            IBiconomyForwarder.ERC20ForwardRequest({
                from: user,
                to: address(allo),
                token: dai,
                txGas: 0,
                tokenGasPrice: 0,
                batchId: 0,
                batchNonce: 0,
                deadline: block.timestamp + 1 days,
                data: abi.encodeWithSelector(
                    allo.createPool.selector,
                    profileId,
                    address(strategy),
                    _initStrategyData,
                    dai,
                    0,
                    Metadata({
                        protocol: 1,
                        pointer: ''
                    }),
                    new address[](0)
                )
            }),
            domainSeparator,
            sig
        );
    }
}