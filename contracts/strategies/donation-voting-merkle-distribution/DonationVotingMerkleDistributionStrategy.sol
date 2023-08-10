// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
// Interfaces
import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";
import {Native} from "../../core/libraries/Native.sol";

contract DonationVotingMerkleDistributionStrategy is BaseStrategy, ReentrancyGuard, Multicall {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    struct ApplicationStatus {
        uint256 index;
        uint256 statusRow;
    }

    /// @notice Struct to hold details of the recipients
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
    }

    /// @notice Struct to hold details of the allocations to claim
    struct Claim {
        address recipientId;
        address token;
    }

    struct Distribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error UNAUTHORIZED();
    error REGISTRATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error RECIPIENT_ERROR(address recipientId);
    error INVALID();
    error NOT_ALLOWED();
    error INVALID_METADATA();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);
    event TimestampsUpdated(
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime,
        address sender
    );
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);
    event BatchPayoutSuccessful(address indexed sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// Metadata containing the distribution
    Metadata public distributionMetadata;

    bool public useRegistryAnchor;
    bool public metadataRequired;
    bool public distributionStarted;
    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;
    uint256 public totalPayoutAmount;
    uint256 public recipientsCounter;

    /// @notice merkle root generated from distribution
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    // statuses[0] is the first row of the bitmap and allows to store 256 bits to describe
    // the status of 256 projects.
    // statuses[1] is the second row, and so on.
    // Instead of using 1 bit for each recipient status, we use 4 bits to allow 5 statuses:
    // 0: none
    // 1: pending
    // 2: accepted
    // 3: rejected
    // 4: appealed
    // Since it's a mapping the storage it's pre-allocated with zero values,
    // so if we check the status of an existing recipient, the value is by default 0 (pending).
    // If we want to check the status of an recipient, we take its index from the `recipients` array
    // and convert it to the 2-bits position in the bitmap.
    mapping(uint256 => uint256) public statusesBitMap;
    // recipientId => statusIndex
    mapping(address => uint256) public recipientToStatusIndexes;

    /// @notice packed array of booleans to keep track of claims
    mapping(uint256 => uint256) private distributedBitMap;

    /// @notice token -> bool
    mapping(address => bool) public allowedTokens;
    /// @notice recipientId -> Recipient
    mapping(address => Recipient) private _recipients;
    /// @notice recipientId -> token -> amount
    mapping(address => mapping(address => uint256)) public claims;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    modifier onlyActiveRegistration() {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyActiveAllocation() {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public virtual override onlyAllo {
        (
            bool _useRegistryAnchor,
            bool _metadataRequired,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime,
            address[] memory _allowedTokens
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, address[]));
        __DonationVotingStrategy_init(
            _poolId,
            _useRegistryAnchor,
            _metadataRequired,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime,
            _allowedTokens
        );
    }

    function __DonationVotingStrategy_init(
        uint256 _poolId,
        bool _useRegistryAnchor,
        bool _metadataRequired,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime,
        address[] memory _allowedTokens
    ) internal {
        __BaseStrategy_init(_poolId);
        useRegistryAnchor = _useRegistryAnchor;
        metadataRequired = _metadataRequired;

        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );

        uint256 allowedTokensLength = _allowedTokens.length;

        if (allowedTokensLength == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        }

        for (uint256 i = 0; i < allowedTokensLength;) {
            allowedTokens[_allowedTokens[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @param _recipientId Id of the recipient
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return InternalRecipientStatus(_getRecipientStatus(_recipientId));
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = InternalRecipientStatus(_getRecipientStatus(_recipientId));
        if (internalStatus == InternalRecipientStatus.Appealed) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    // Statuses:
    // * 0 - none
    // * 1 - pending
    // * 2 - approved
    // * 3 - rejected
    // * 4 - appealed
    /// Set recipient statuses
    /// @param statuses new statuses
    function reviewRecipients(ApplicationStatus[] memory statuses)
        external
        onlyActiveRegistration
        onlyPoolManager(msg.sender)
    {
        for (uint256 i = 0; i < statuses.length;) {
            uint256 rowIndex = statuses[i].index;
            uint256 fullRow = statuses[i].statusRow;

            statusesBitMap[rowIndex] = fullRow;

            emit RecipientStatusUpdated(rowIndex, fullRow, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// @notice Withdraw funds from pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        if (block.timestamp <= allocationEndTime + 30 days) {
            revert NOT_ALLOWED();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);

        if (_amount > poolAmount) {
            revert NOT_ALLOWED();
        }

        poolAmount -= _amount;
        _transferAmount(pool.token, msg.sender, _amount);
    }

    /// @notice Claim allocated tokens
    /// @param _claims Claims to be claimed
    function claim(Claim[] calldata _claims) external nonReentrant onlyAfterAllocation {
        uint256 claimsLength = _claims.length;
        for (uint256 i; i < claimsLength;) {
            Claim memory singleClaim = _claims[i];
            Recipient memory recipient = _recipients[singleClaim.recipientId];
            uint256 amount = claims[singleClaim.recipientId][singleClaim.token];

            if (amount == 0) {
                revert INVALID();
            }

            claims[singleClaim.recipientId][singleClaim.token] = 0;

            address token = singleClaim.token;

            _transferAmount(token, recipient.recipientAddress, amount);

            emit Claimed(singleClaim.recipientId, recipient.recipientAddress, amount, token);
            unchecked {
                i++;
            }
        }
    }

    /// ==================================
    /// ============ Merkle ==============
    /// ==================================

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata
    /// @param encodedDistribution encoded distribution
    function updateDistribution(bytes calldata encodedDistribution)
        external
        onlyAfterAllocation
        onlyPoolManager(msg.sender)
    {
        if (distributionStarted) {
            revert INVALID();
        }

        (bytes32 _merkleRoot, Metadata memory _distributionMetadata) =
            abi.decode(encodedDistribution, (bytes32, Metadata));

        merkleRoot = _merkleRoot;
        distributionMetadata = _distributionMetadata;

        emit DistributionUpdated(merkleRoot, distributionMetadata);
    }

    /// @notice function to check if distribution is set
    function isDistributionSet() external view returns (bool) {
        return merkleRoot != "";
    }

    /// @notice Util function to check if distribution is done
    /// @param _index index of the distribution
    function hasBeenDistributed(uint256 _index) external view returns (bool) {
        return _hasBeenDistributed(_index);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if address is elgible allocator
    function _isValidAllocator(address) internal pure override returns (bool) {
        return true;
    }

    function _isPoolTimestampValid(
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal view {
        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }
    }

    /// @notice Returns status of the pool
    function _isPoolActive() internal view override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Submit recipient to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (useRegistryAnchor) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        Recipient storage recipient = _recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = useRegistryAnchor ? true : isUsingRegistryAnchor;

        uint8 currentStatus = _getRecipientStatus(recipientId);

        if (currentStatus == uint8(InternalRecipientStatus.Rejected)) {
            _setRecipientStatus(recipientId, uint8(InternalRecipientStatus.Appealed));
            emit Appealed(recipientId, _data, _sender);
        } else {
            recipientToStatusIndexes[recipientId] = recipientsCounter;
            _setRecipientStatus(recipientId, uint8(InternalRecipientStatus.Pending));

            bytes memory extendedData = abi.encode(_data, recipientsCounter);
            emit Registered(recipientId, extendedData, _sender);

            recipientsCounter++;
        }
    }

    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActiveAllocation
    {
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));

        if (InternalRecipientStatus(_getRecipientStatus(recipientId)) != InternalRecipientStatus.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        if (msg.value > 0 && token != NATIVE || token == NATIVE && msg.value != amount) {
            revert INVALID();
        }

        _transferAmount(token, address(this), amount);

        claims[recipientId][token] += amount;

        emit Allocated(recipientId, amount, token, _sender);
    }

    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (!distributionStarted) {
            distributionStarted = true;
        }

        Distribution[] memory distributions = abi.decode(_data, (Distribution[]));

        uint256 length = distributions.length;
        for (uint256 i = 0; i < length;) {
            _distributeSingle(distributions[i]);
            unchecked {
                i++;
            }
        }

        emit BatchPayoutSuccessful(_sender);
    }

    /// @notice Check if sender is profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    function _isProfileMember(address _anchor, address _sender) internal view virtual returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_anchor);
        return registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return _recipients[_recipientId];
    }

    /// @notice Returns the payout summary for the accepted recipient
    function _getPayout(address, bytes memory _data) internal view override returns (PayoutSummary memory) {
        Distribution memory distribution = abi.decode(_data, (Distribution));

        uint256 index = distribution.index;
        address recipientId = distribution.recipientId;
        uint256 amount = distribution.amount;
        bytes32[] memory merkleProof = distribution.merkleProof;

        address recipientAddress = _getRecipient(recipientId).recipientAddress;

        if (_validateDistribution(index, recipientAddress, amount, recipientId, merkleProof)) {
            return PayoutSummary(recipientAddress, amount);
        }
        return PayoutSummary(recipientAddress, 0);
    }

    function _validateDistribution(
        uint256 _index,
        address _recipientId,
        uint256 _amount,
        address _recipientAddress,
        bytes32[] memory _merkleProof
    ) internal view returns (bool) {
        if (_hasBeenDistributed(_index)) {
            return false;
        }

        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _recipientAddress, _amount, _recipientId))));

        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            return false;
        }

        return true;
    }

    function _hasBeenDistributed(uint256 _index) internal view returns (bool) {
        uint256 distributedWordIndex = _index / 256;
        uint256 distributedBitIndex = _index % 256;
        uint256 distributedWord = distributedBitMap[distributedWordIndex];
        uint256 mask = (1 << distributedBitIndex);

        return distributedWord & mask == mask;
    }

    /// @notice Util function to mark distribution as done
    /// @param _index index of the distribution
    function _setDistributed(uint256 _index) private {
        uint256 distributedWordIndex = _index / 256;
        uint256 distributedBitIndex = _index % 256;
        distributedBitMap[distributedWordIndex] |= (1 << distributedBitIndex);
    }

    /// @notice Util function to distribute funds to recipient
    /// @param _distribution encoded distribution
    function _distributeSingle(Distribution memory _distribution) private {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId;
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        address recipientAddress = _recipients[recipientId].recipientAddress;

        if (_validateDistribution(index, recipientId, amount, recipientAddress, merkleProof)) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            _setDistributed(index);
            poolAmount -= amount;
            _transferAmount(pool.token, payable(recipientAddress), amount);

            emit FundsDistributed(amount, recipientAddress, pool.token, recipientId);
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }
    }

    /// @notice set recipient status
    /// @param _recipientId Id of the recipient
    /// @param _status Status of the recipient
    function _setRecipientStatus(address _recipientId, uint256 _status) internal {
        (uint256 rowIndex, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);

        uint256 newRow = currentRow & ~(15 << colIndex);
        statusesBitMap[rowIndex] = newRow | (_status << colIndex);
    }

    /// @notice Get recipient status
    /// @param _recipientId index of the recipient
    /// @return status status of the recipient
    function _getRecipientStatus(address _recipientId) internal view returns (uint8) {
        (, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);
        uint8 status = uint8((currentRow >> colIndex) & 15);
        return status;
    }

    /// @notice get recipient status rowIndex, colIndex and currentRow
    /// @param _recipientId Id of the recipient
    /// @return rowIndex, colIndex, currentRow
    function _getStatusRowColumn(address _recipientId) internal view returns (uint256, uint256, uint256) {
        uint256 recipientIndex = recipientToStatusIndexes[_recipientId];

        if (recipientIndex > recipientsCounter) {
            revert INVALID();
        }

        uint256 rowIndex = recipientIndex / 64; // 256 / 4
        uint256 colIndex = (recipientIndex % 64) * 4;

        return (rowIndex, colIndex, statusesBitMap[rowIndex]);
    }

    receive() external payable {}
}
