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

/// @notice This script is used to create test data for the Allo V2 contracts
/// @author -
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/CreateTestData.s.sol:CreateTestData --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CreateTestData is Script, Native {
    address payable strategyAddress = payable(address(0xC88612a4541A28c221F3d03b6Cf326dCFC557C4E));

    // Initialize the Allo Interface
    Allo allo = Allo(0x79536CC062EE8FAFA7A19a5fa07783BD7F792206);

    // Initialize Registry Interface
    IRegistry registry = IRegistry(0xAEc621EC8D9dE4B524f4864791171045d6BBBe27);

    // Initialize Strategy
    DonationVotingMerkleDistributionBaseStrategy strategy =
        DonationVotingMerkleDistributionBaseStrategy(strategyAddress);

    // adding a nonce for reusability
    uint256 nonce = block.timestamp;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address owner = vm.addr(deployerPrivateKey);

        // Create a profile
        address[] memory members = new address[](1);
        members[0] = address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42);

        bytes32 profileId = registry.createProfile(
            nonce, "Test Profile", Metadata({protocol: 1, pointer: "TestProfileMetadata"}), owner, members
        );

        IRegistry.Profile memory profile = registry.getProfileById(profileId);

        // Create A Pool using Donation Voting Merkle Distribution V1
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(NATIVE);

        bytes memory encodedStrategyData = abi.encode(
            true, true, block.timestamp, block.timestamp + 10, block.timestamp + 20, block.timestamp + 30, allowedTokens
        );

        Metadata memory metadata = Metadata({protocol: 1, pointer: "TestPoolMetadataPointer"});
        address[] memory managers = new address[](1);
        managers[0] = address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42);

        uint256 poolId = allo.createPool(profileId, strategyAddress, encodedStrategyData, NATIVE, 0, metadata, managers);

        // Fund the Pool
        allo.fundPool{value: 1e16}(poolId, 1e16);

        // Register 2 recipients
        Metadata memory recipientMetadata1 = Metadata({protocol: 1, pointer: "TestRecipientMetadataPointer1"});
        Metadata memory recipientMetadata2 = Metadata({protocol: 1, pointer: "TestRecipientMetadataPointer2"});
        // data should be encoded: (recipientId, recipientAddress, metadata) this strategy uses the anchor
        bytes memory recipientData1 =
            abi.encode(profile.anchor, 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42, recipientMetadata1);
        bytes memory recipientData2 =
            abi.encode(profile.anchor, 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42, recipientMetadata2);
        address recipientId1 = allo.registerRecipient(poolId, recipientData1);
        address recipientId2 = allo.registerRecipient(poolId, recipientData2);

        // Approve 1 recipient
        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
        new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](
                2
            );
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 2});

        // Reject 1 recipient
        statuses[1] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 1, statusRow: 3});

        // TODO: Somehow need to wait for a block to mine to be able to review recipients in the registration period
        // strategy.reviewRecipients(statuses);

        // Update Timestamps
        // strategy.updatePoolTimestamps(
        //     uint64(block.timestamp + 10),
        //     uint64(block.timestamp + 20),
        //     uint64(block.timestamp + 30),
        //     uint64(block.timestamp + 40)
        // );

        // Cast a vote
        // ISignatureTransfer.TokenPermissions memory tokenPermissions =
        //     ISignatureTransfer.TokenPermissions({token: address(NATIVE), amount: 1e16});
        // ISignatureTransfer.PermitTransferFrom memory permit =
        //     ISignatureTransfer.PermitTransferFrom({permitted: tokenPermissions, nonce: 0, deadline: 1000000});
        // DonationVotingMerkleDistributionBaseStrategy.Permit2Data memory permit2Data =
        // DonationVotingMerkleDistributionBaseStrategy.Permit2Data({
        //     permit: permit,
        //     signature: abi.encodePacked(
        //         uint8(1), uint8(27), address(0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42), uint8(0), uint8(0)
        //         )
        // });
        // bytes memory allocateData1 = abi.encode(recipientId1, permit2Data);
        // bytes memory allocateData2 = abi.encode(recipientId2, permit2Data);

        // TODO: Somehow need to wait for a block to mine to be able to allocate in the allocation period
        // allo.allocate(poolId, allocateData1);
        // allo.allocate(poolId, allocateData2);

        vm.stopBroadcast();
    }
}
