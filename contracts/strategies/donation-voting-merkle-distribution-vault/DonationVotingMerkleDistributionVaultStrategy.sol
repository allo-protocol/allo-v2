// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {DonationVotingMerkleDistributionBaseStrategy} from
    "../donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
contract DonationVotingMerkleDistributionVaultStrategy is
    DonationVotingMerkleDistributionBaseStrategy,
    ReentrancyGuard
{
    /// @notice Stores the details of the allocations to claim.
    struct Claim {
        address recipientId;
        address token;
    }

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a recipient has claimed their allocated funds
    /// @param recipientId Id of the recipient
    /// @param recipientAddress Address of the recipient
    /// @param amount Amount of tokens claimed
    /// @param token Address of the token
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice 'recipientId' => 'token' => 'amount'.
    mapping(address => mapping(address => uint256)) public claims;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) DonationVotingMerkleDistributionBaseStrategy(_allo, _name) {}

    /// @notice Claim allocated tokens for recipients.
    /// @dev Uses the merkle root to verify the claims. Allocation must have ended to claim.
    /// @param _claims Claims to be claimed
    function claim(Claim[] calldata _claims) external nonReentrant onlyAfterAllocation {
        uint256 claimsLength = _claims.length;

        // Loop through the claims
        for (uint256 i; i < claimsLength;) {
            Claim memory singleClaim = _claims[i];
            Recipient memory recipient = _recipients[singleClaim.recipientId];
            uint256 amount = claims[singleClaim.recipientId][singleClaim.token];

            // If the claim amount is zero this will revert
            if (amount == 0) {
                revert INVALID();
            }

            /// Delete the claim from the mapping
            delete claims[singleClaim.recipientId][singleClaim.token];

            address token = singleClaim.token;

            // Transfer the tokens to the recipient
            _transferAmount(token, recipient.recipientAddress, amount);

            // Emit that the tokens have been claimed and sent to the recipient
            emit Claimed(singleClaim.recipientId, recipient.recipientAddress, amount, token);
            unchecked {
                i++;
            }
        }
    }

    /// ================================
    /// ============ Hooks =============
    /// ================================

    /// @notice After allocation hook to store the allocated tokens in the vault
    /// @param _data The encoded recipientId, amount and token
    /// @param _sender The sender of the allocation
    function _afterAllocate(bytes memory _data, address _sender) internal override {
        // Decode the '_data' to get the recipientId, amount and token
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));

        _transferAmountFrom(token, TransferData({from: _sender, to: address(this), amount: amount}));

        // Update the total payout amount for the claim
        claims[recipientId][token] += amount;
    }
}
