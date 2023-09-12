// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../contracts/core/Allo.sol";
import {IRegistry} from "../contracts/core/interfaces/IRegistry.sol";
import {IStrategy} from "../contracts/core/interfaces/IStrategy.sol";

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {Metadata} from "../contracts/core/libraries/Metadata.sol";
import {Native} from "../contracts/core/libraries/Native.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

contract CreateTestData is Script, Native {
    address payable strategyAddress = payable(address(0xC88612a4541A28c221F3d03b6Cf326dCFC557C4E));

    // Initialize the Allo Interface
    Allo allo = Allo(0x8dDe1922d5f772890f169714FACeEF9551791CaF);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(0xAEc621EC8D9dE4B524f4864791171045d6BBBe27);

    // Initialize Strategy
    DonationVotingMerkleDistributionBaseStrategy strategy =
        DonationVotingMerkleDistributionBaseStrategy(strategyAddress);

    // adding a nonce for reusability
    uint256 nonce = 1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create a profile
        address[] memory members = new address[](2);
        members[0] = address(makeAddr("MEMBER1"));
        members[1] = address(makeAddr("MEMBER2"));

        bytes32 profileId = registry.createProfile(
            nonce++,
            "Test Profile",
            Metadata({protocol: 1, pointer: "TestProfile"}),
            address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42),
            members
        );

        // Create A Pool using Donation Voting Merkle Distribution V1
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(NATIVE);

        DonationVotingMerkleDistributionBaseStrategy.InitializeData memory strategyData =
        DonationVotingMerkleDistributionBaseStrategy.InitializeData({
            useRegistryAnchor: true,
            metadataRequired: true,
            registrationStartTime: uint64(block.timestamp),
            registrationEndTime: uint64(block.timestamp) + 10000,
            allocationStartTime: uint64(block.timestamp) + 20000,
            allocationEndTime: uint64(block.timestamp) + 30000,
            allowedTokens: allowedTokens
        });
        bytes memory encodedStrategyData = abi.encode(strategyData);

        Metadata memory metadata = Metadata({protocol: 1, pointer: "TestPool"});
        address[] memory managers = new address[](2);
        managers[0] = address(makeAddr("MANAGER1"));
        managers[1] = address(makeAddr("MANAGER2"));

        uint256 poolId = allo.createPool(profileId, strategyAddress, encodedStrategyData, NATIVE, 0, metadata, managers);

        // Fund the Pool
        allo.fundPool(poolId, 1e16);

        // Register 2 recipients
        bytes memory recipientData1 = abi.encode("recipient1");
        bytes memory recipientData2 = abi.encode("recipient2");
        address recipientId1 = allo.registerRecipient(poolId, recipientData1);
        address recipientId2 = allo.registerRecipient(poolId, recipientData2);

        // Approve 1 recipient
        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](2);
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 2});

        // Reject 1 recipient
        statuses[1] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 1, statusRow: 3});

        strategy.reviewRecipients(statuses);

        // Update Timestamps
        strategy.updatePoolTimestamps(uint64(10001), uint64(20001), uint64(30001), uint64(40001));

        // Cast a vote
        ISignatureTransfer.TokenPermissions memory tokenPermissions =
            ISignatureTransfer.TokenPermissions({token: address(NATIVE), amount: 1e16});
        ISignatureTransfer.PermitTransferFrom memory permit =
            ISignatureTransfer.PermitTransferFrom({permitted: tokenPermissions, nonce: 0, deadline: 1000000});
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
            permit: permit,
            signature: abi.encodePacked(
                uint8(1), uint8(27), address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42), uint8(0), uint8(0)
                )
        });
        bytes memory allocateData = abi.encode(recipientId1, 1e16);
        allo.allocate(poolId, allocateData);

        vm.stopBroadcast();
    }
}
