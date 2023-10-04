// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {IRegistry} from "../../../contracts/core/interfaces/IRegistry.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {GoerliConfig} from "./../../GoerliConfig.sol";

import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

/// @notice This script is used to create test data for the Allo V2 contracts
/// @dev Use this to run
///      'source .env' if you are using a .env file for your rpc-url
///      'forge script script/strategy/donation-voting/CastVote.s.sol:CastVote --rpc-url $GOERLI_RPC_URL --broadcast  -vvvv'
contract CastVote is Script, Native, GoerliConfig {
    // Initialize the Allo Interface
    Allo allo = Allo(ALLO);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

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
        bytes memory allocateData1 = abi.encode(TEST_RECIPIENT_ID_1, permit2Data);
        bytes memory allocateData2 = abi.encode(TEST_RECIPIENT_ID_2, permit2Data);

        allo.allocate(TEST_POOL_1, allocateData1);
        allo.allocate(TEST_POOL_1, allocateData2);

        vm.stopBroadcast();
    }
}
