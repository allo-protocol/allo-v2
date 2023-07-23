// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {IAllo} from "../../core/IAllo.sol";

/**
 * @notice Merkle Payout Strategy contract which is deployed once per round
 * and is used to upload the final match distribution.
 *
 */
contract MerklePayoutStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /// ======================
    /// ======= Errors =======
    /// ======================

    /// ================================
    /// ========== Storage =============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        InReview
    }

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        InternalRecipientStatus recipientStatus;
    }

    /// @notice Struct to hold milestone details
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        RecipientStatus milestoneStatus;
    }

    /// @notice merkle root generated from distribution
    bytes32 public merkleRoot;

    /// @notice flag to check if distribution is set
    bool public isReadyForPayout;

    /// @notice token address
    address public tokenAddress;

    /// @notice packed array of booleans to keep track of claims
    mapping(uint256 => uint256) private distributedBitMap;

    /// Metadata containing the distribution
    Metadata public distributionMetaPtr;

    // --- Events ---

    /// @notice Emitted when funds are withdrawn from the payout contract
    event FundsWithdrawn(address indexed tokenAddress, uint256 amount, address withdrawAddress);

    /// @notice Emitted when the distribution is updated
    event DistributionUpdated(bytes32 merkleRoot, Metadata distributionMetaPtr);

    /// @notice Emitted when funds are distributed
    event FundsDistributed(uint256 amount, address grantee, address indexed token, bytes32 indexed projectId);

    /// @notice Emitted when batch payout is successful
    event BatchPayoutSuccessful(address indexed sender);

    // --- Types ---
    struct Distribution {
        uint256 index;
        address grantee;
        uint256 amount;
        bytes32[] merkleProof;
        bytes32 projectId;
    }

    /// ================================
    /// ======== Constructor ===========
    /// ================================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    // @NOTE: we need this because we're inheriting from Initializable.sol
    function initialize(uint256 _poolId, bytes memory /* _data */ ) public override {
        // todo:
        __MerklePayoutStrategy_init(_poolId);
    }

    function __MerklePayoutStrategy_init(uint256 _poolId) internal {
        // todo:

        __BaseStrategy_init(_poolId);
    }

    // --- Core methods ---

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        // return _getRecipient(_recipientId).recipientStatus;
    }

    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {}

    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {}

    function _allocate(bytes memory _data, address _sender) internal virtual override {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    // todo:

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata
    /// @param encodedDistribution encoded distribution
    function updateDistribution(bytes calldata encodedDistribution) external onlyPoolManager(msg.sender) {
        require(isReadyForPayout == false, "Payout: Already ready for payout");

        (bytes32 _merkleRoot, Metadata memory _distributionMetaPtr) =
            abi.decode(encodedDistribution, (bytes32, Metadata));

        merkleRoot = _merkleRoot;
        distributionMetaPtr = _distributionMetaPtr;

        emit DistributionUpdated(merkleRoot, distributionMetaPtr);
    }

    /// @notice function to check if distribution is set
    function isDistributionSet() public view returns (bool) {
        return merkleRoot != "";
    }

    /// @notice Invoked by RoundImplementation to set isReadyForPayout
    function setReadyForPayout() external payable onlyPoolManager(msg.sender) {
        require(isReadyForPayout == false, "isReadyForPayout already set");
        require(isDistributionSet(), "distribution not set");

        isReadyForPayout = true;
    }

    /// @notice Util function to check if distribution is done
    /// @param _index index of the distribution
    function hasBeenDistributed(uint256 _index) public view returns (bool) {
        uint256 distributedWordIndex = _index / 256;
        uint256 distributedBitIndex = _index % 256;
        uint256 distributedWord = distributedBitMap[distributedWordIndex];
        uint256 mask = (1 << distributedBitIndex);

        return distributedWord & mask == mask;
    }

    /**
     * @notice Invoked by RoundImplementation to withdraw funds to
     * withdrawAddress from the payout contract
     *
     * @param withdrawAddress withdraw funds address
     */
    function withdrawFunds(address payable withdrawAddress) external payable onlyPoolManager(msg.sender) {
        uint256 balance = _getTokenBalance();

        _transferAmount(tokenAddress, withdrawAddress, balance);

        emit FundsWithdrawn(tokenAddress, balance, withdrawAddress);
    }

    /// @notice function to distribute funds to recipient
    /// @dev can be invoked only by round operator
    /// @param _distributions encoded distribution
    function payout(Distribution[] calldata _distributions) external payable onlyPoolManager(msg.sender) {
        require(isReadyForPayout == true, "Payout: Not ready for payout");

        for (uint256 i = 0; i < _distributions.length; ++i) {
            _distribute(_distributions[i]);
        }

        emit BatchPayoutSuccessful(msg.sender);
    }

    /// @notice Util function to distribute funds to recipient
    /// @param _distribution encoded distribution
    function _distribute(Distribution calldata _distribution) private {
        uint256 _index = _distribution.index;
        address _grantee = _distribution.grantee;
        uint256 _amount = _distribution.amount;
        bytes32 _projectId = _distribution.projectId;
        bytes32[] memory _merkleProof = _distribution.merkleProof;

        require(!hasBeenDistributed(_index), "Payout: Already distributed");

        /* We need double hashing to prevent second preimage attacks */
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _grantee, _amount, _projectId))));

        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "Payout: Invalid proof");

        _setDistributed(_index);

        _transferAmount(payable(_grantee), _amount);

        emit FundsDistributed(_amount, _grantee, tokenAddress, _projectId);
    }

    /// @notice Util function to mark distribution as done
    /// @param _index index of the distribution
    function _setDistributed(uint256 _index) private {
        uint256 distributedWordIndex = _index / 256;
        uint256 distributedBitIndex = _index % 256;
        distributedBitMap[distributedWordIndex] |= (1 << distributedBitIndex);
    }

    /// @notice Util function to transfer amount to recipient
    /// @param _recipient recipient address
    /// @param _amount amount to transfer
    function _transferAmount(address payable _recipient, uint256 _amount) private {
        if (tokenAddress == address(0)) {
            Address.sendValue(_recipient, _amount);
        } else {
            IERC20(tokenAddress).safeTransfer(_recipient, _amount);
        }
    }

    /**
     * Util function to get token balance in the contract
     */
    function _getTokenBalance() internal view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
    }
}
