// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
// Interfaces
import {IAllo} from "../core/interfaces/IAllo.sol";
// Core Contracts
import {DonationVotingOffchain} from "./DonationVotingOffchain.sol";
// Internal Libraries
import {Metadata} from "../core/libraries/Metadata.sol";
import {Errors} from "../core/libraries/Errors.sol";
import {Native} from "../core/libraries/Native.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Donation Voting Strategy with off-chain setup
/// @notice Strategy that allows allocations in multiple tokens to accepted recipient. The actual payouts are set
/// by the pool manager.
contract DonationVotingMerkleDistribution is DonationVotingOffchain {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the distribution has been updated with a new merkle root or metadata
    /// @param merkleRoot The merkle root of the distribution
    /// @param metadata The metadata of the distribution
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);

    /// ================================
    /// ========== Errors ==============
    /// ================================

    /// @notice Thrown when the merkle root is attempted to be updated but the distribution is ongoing
    error DISTRIBUTION_ALREADY_STARTED();

    /// @notice Thrown when distribution is invoked but the merkle root has not been set yet
    error MERKLE_ROOT_NOT_SET();

    /// @notice Thrown when distribution is attempted twice for the same 'index'
    error ALREADY_DISTRIBUTED(uint256 _index);

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the distribution.
    struct Distribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Metadata containing the distribution data.
    Metadata public distributionMetadata;

    /// @notice Flag to indicate whether the distribution has started or not.
    bool public distributionStarted;

    /// @notice The merkle root of the distribution will be set by the pool manager.
    bytes32 public merkleRoot;

    /// @notice This is a packed array of booleans to keep track of claims distributed.
    /// @dev _distributedBitMap[0] is the first row of the bitmap and allows to store 256 bits to describe
    /// the status of 256 claims
    mapping(uint256 => uint256) private _distributedBitMap;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Offchain strategy
    /// @param _allo The 'Allo' contract
    constructor(address _allo) DonationVotingOffchain(_allo) {}

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata.
    /// @param _data The data to be decoded
    /// @custom:data (bytes32 _merkleRoot, Metadata _distributionMetadata)
    function setPayout(bytes memory _data) external override onlyPoolManager(msg.sender) onlyAfterAllocation {
        // The merkleRoot can only be updated before the distribution has started
        if (distributionStarted) revert DISTRIBUTION_ALREADY_STARTED();

        (bytes32 _merkleRoot, Metadata memory _distributionMetadata) = abi.decode(_data, (bytes32, Metadata));

        merkleRoot = _merkleRoot;
        distributionMetadata = _distributionMetadata;

        // Emit that the distribution has been updated
        emit DistributionUpdated(_merkleRoot, _distributionMetadata);
    }

    /// @notice Utility function to check if distribution is done.
    /// @param _index index of the distribution
    /// @return 'true' if distribution is completed, otherwise 'false'
    function hasBeenDistributed(uint256 _index) external view returns (bool) {
        return _hasBeenDistributed(_index);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Distributes funds (tokens) to recipients.
    /// @param _data Data to be decoded
    /// @custom:data (Distribution[] _distributions)
    /// @param _sender The address of the sender
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        if (merkleRoot == bytes32(0)) revert MERKLE_ROOT_NOT_SET();

        if (!distributionStarted) {
            distributionStarted = true;
        }

        // Decode the '_data' to get the distributions
        Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
        uint256 length = distributions.length;

        // Loop through the distributions and distribute the funds
        IAllo.Pool memory pool = allo.getPool(poolId);
        for (uint256 i; i < length;) {
            _distributeSingle(distributions[i], pool.token, _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if the distribution has been distributed.
    /// @param _index index of the distribution
    /// @return 'true' if the distribution has been distributed, otherwise 'false'
    function _hasBeenDistributed(uint256 _index) internal view returns (bool) {
        uint256 wordIndex = _index / 256;
        uint256 distributedWord = _distributedBitMap[wordIndex];

        uint256 bitIndex = _index % 256;
        // Get the mask by shifting 1 to the left of the 'bitIndex'
        uint256 mask = (1 << bitIndex);

        // Return 'true' if the 'distributedWord' is 1 at 'bitIndex'
        return distributedWord & mask == mask;
    }

    /// @notice Mark distribution as done.
    /// @param _index index of the distribution
    function _setDistributed(uint256 _index) private {
        uint256 wordIndex = _index / 256;
        uint256 distributedWord = _distributedBitMap[wordIndex];

        uint256 bitIndex = _index % 256;
        // Get the mask by shifting 1 to the left of the 'bitIndex'
        uint256 mask = (1 << bitIndex);

        // Revert if the 'distributedWord' is 1 at 'bitIndex', i.e. index was already distributed
        if (distributedWord & mask == mask) revert ALREADY_DISTRIBUTED(_index);

        // Set the 'bitIndex' of 'distributedWord' to 1
        _distributedBitMap[wordIndex] = distributedWord | (1 << bitIndex);
    }

    /// @notice Distribute funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _distribution Distribution to be distributed
    function _distributeSingle(Distribution memory _distribution, address poolToken, address _sender) private {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId; // TODO: is accepted?
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        if (!_isAcceptedRecipient(recipientId)) {
            revert DonationVotingOffchain_RecipientNotAccepted(recipientId);
        }

        // Generate the node that will be verified in the 'merkleRoot'
        bytes32 node = keccak256(abi.encode(index, recipientId, amount));

        // Validate the distribution and transfer the funds to the recipient, otherwise revert if not valid
        if (MerkleProof.verify(merkleProof, merkleRoot, node)) {
            poolAmount -= amount;
            _setDistributed(index);

            address recipientAddress = _recipients[recipientId].recipientAddress;
            _transferAmount(poolToken, recipientAddress, amount);

            emit Distributed(recipientId, abi.encode(recipientAddress, amount, _sender));
        }
    }
}
