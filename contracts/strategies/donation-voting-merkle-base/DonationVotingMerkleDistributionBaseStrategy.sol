// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";
// Interfaces
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";
import {Native} from "../../core/libraries/Native.sol";

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
abstract contract DonationVotingMerkleDistributionBaseStrategy is Native, BaseStrategy, ReentrancyGuard, Multicall {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the internal status of a recipient for this strategy.
    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    /// @notice Struct to hold details of the application status
    /// @dev Application status is stored in a bitmap. Each 4 bits represents the status of a recipient,
    /// defined as 'index' here. The first 4 bits of the 256 bits represent the status of the first recipient,
    /// the second 4 bits represent the status of the second recipient, and so on.
    ///
    /// The 'rowIndex' is the index of the row in the bitmap, and the 'statusRow' is the value of the row.
    /// The 'statusRow' is updated when the status of a recipient changes.
    ///
    /// Note: Since we need 4 bits to store a status, one row of the bitmap can hold the status information of 256/4 recipients.
    ///
    /// For example, if we have 5 recipients, the bitmap will look like this:
    /// | recipient1 | recipient2 | recipient3 | recipient4 | recipient5 | 'rowIndex'
    /// |     0000   |    0001    |    0010    |    0011    |    0100    | 'statusRow'
    /// |     none   |   pending  |  accepted  |  rejected  |  appealed  | converted status (0, 1, 2, 3, 4)
    ///
    struct ApplicationStatus {
        uint256 index;
        uint256 statusRow;
    }

    /// @notice Stores the details of the recipients.
    struct Recipient {
        // If false, the recipientAddress is the anchor of the profile
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
    }

    /// @notice Stores the details of the distribution.
    struct Distribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when the sender is not not a profile member.
    error UNAUTHORIZED();

    /// @notice Throws when registration is not active.
    error REGISTRATION_NOT_ACTIVE();

    /// @notice Throws when allocation is not active.
    error ALLOCATION_NOT_ACTIVE();

    /// @notice Throws when allocation has not ended.
    error ALLOCATION_NOT_ENDED();

    /// @notice Throws when there is an error with the recipient. This can occur when the recipient
    ///      is not registered or the recipient is not accepted.
    /// @param recipientId Id of the recipient
    error RECIPIENT_ERROR(address recipientId);

    /// @notice Throws when a genral error occurs.
    /// @dev Used as a general error message for this strategy. This can occur when a token is not
    ///      allowed or the amount is invalid and is specific to this strategy.
    error INVALID();

    /// @notice Throws when 30 days have not passed since the end of the allocation or
    ///         the amount is greater than the pool amount.
    error NOT_ALLOWED();

    /// @notice Throws when the metadata is invalid, protocol or pointer is not set.
    error INVALID_METADATA();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId Id of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    /// @param status The updated status of the recipient
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);

    /// @notice Emitted when a recipient is registered and the status is updated
    /// @param rowIndex The index of the row in the bitmap
    /// @param fullRow The value of the row
    /// @param sender The sender of the transaction
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);

    /// @notice Emitted when the timestamps are updated
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event TimestampsUpdated(
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime,
        address sender
    );

    /// @notice Emitted when the distribution has been updated with a new merkle root or metadata
    /// @param merkleRoot The merkle root of the distribution
    /// @param metadata The metadata of the distribution
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);

    /// @notice Emitted when funds are distributed to a recipient
    /// @param amount The amount of tokens distributed
    /// @param grantee The address of the recipient
    /// @param token The address of the token
    /// @param recipientId The id of the recipient
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);

    /// @notice Emitted when a batch payout is successful
    /// @param sender The sender of the transaction
    event BatchPayoutSuccessful(address indexed sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Metadata containing the distribution data.
    Metadata public distributionMetadata;

    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public useRegistryAnchor;

    /// @notice Flag to indicate whether metadata is required or not.
    bool public metadataRequired;

    /// @notice Flag to indicate whether the distribution has started or not.
    bool public distributionStarted;

    /// @notice The timestamps in milliseconds for the start and end times.
    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    /// @notice The total amount of tokens allocated to the payout.
    uint256 public totalPayoutAmount;

    /// @notice The total number of recipients.
    uint256 public recipientsCounter;

    /// @notice The registry contract interface.
    IRegistry private _registry;

    /// @notice The merkle root of the distribution will be set by the pool manager.
    bytes32 public merkleRoot;

    /// @notice This is a packed array of booleans, 'statuses[0]' is the first row of the bitmap and allows to
    /// store 256 bits to describe the status of 256 projects. 'statuses[1]' is the second row, and so on
    /// Instead of using 1 bit for each recipient status, we will use 4 bits for each status
    /// to allow 5 statuses:
    /// 0: none
    /// 1: pending
    /// 2: accepted
    /// 3: rejected
    /// 4: appealed
    /// Since it's a mapping the storage it's pre-allocated with zero values, so if we check the
    /// status of an existing recipient, the value is by default 0 (none).
    /// If we want to check the status of an recipient, we take its index from the `recipients` array
    /// and convert it to the 2-bits position in the bitmap.
    mapping(uint256 => uint256) public statusesBitMap;

    /// @notice 'recipientId' => 'statusIndex'
    /// @dev 'statusIndex' is the index of the recipient in the 'statusesBitMap' bitmap.
    mapping(address => uint256) public recipientToStatusIndexes;

    /// @notice This is a packed array of booleans to keep track of claims distributed.
    /// @dev distributedBitMap[0] is the first row of the bitmap and allows to store 256 bits to describe
    /// the status of 256 claims
    mapping(uint256 => uint256) private distributedBitMap;

    /// @notice 'token' address => boolean (allowed = true).
    /// @dev This can be updated by the pool manager.
    mapping(address => bool) public allowedTokens;

    /// @notice 'recipientId' => 'Recipient' struct.
    mapping(address => Recipient) internal _recipients;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Checks if the registration is active and reverts if not.
    modifier onlyActiveRegistration() {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
        _;
    }

    /// @notice Checks if the allocation is active and reverts if not.
    modifier onlyActiveAllocation() {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    /// @notice Checks if the allocation has ended and reverts if not.
    modifier onlyAfterAllocation() {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initializes the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId The 'poolId' to initialize
    /// @param _data The data to be decoded to initialize the strategy
    /// @custom:data (bool _useRegistryAnchor, bool _metadataRequired, uint256 _registrationStartTime,
    ///               uint256 _registrationEndTime, uint256 _allocationStartTime, uint256 _allocationEndTime,
    ///               address[] memory _allowedTokens)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override onlyAllo {
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

    /// @notice Initializes this strategy as well as the BaseStrategy.
    /// @dev This will revert if the strategy is already initialized.
    /// @param _poolId The 'poolId' to initialize
    /// @param _useRegistryAnchor If 'true', the 'recipientAddress' is the anchor of the profile
    /// @param _metadataRequired If 'true', the metadata is required
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    /// @param _allowedTokens The addresses of the allowed tokens you want for the strategy
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
        // Initialize the BaseStrategy with the '_poolId'
        __BaseStrategy_init(_poolId);

        // Initialize required values
        useRegistryAnchor = _useRegistryAnchor;
        metadataRequired = _metadataRequired;
        _registry = allo.getRegistry();

        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);

        // Set the updated timestamps
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );

        uint256 allowedTokensLength = _allowedTokens.length;

        // If the length of the allowed tokens is zero, we will allow all tokens
        if (allowedTokensLength == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        }

        // Loop through the allowed tokens and set them to true
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

    /// @notice Get a recipient with a '_recipientId'
    /// @param _recipientId ID of the recipient
    /// @return recipient Returns the recipient details
    function getRecipient(address _recipientId) external view returns (Recipient memory recipient) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @dev This will return the 'InternalRecipientStatus' of the recipient, the 'InternalRecipientStatus' is
    ///      used at the protocol level and is different from the 'RecipientStatus' which is used at the strategy
    ///      level
    /// @param _recipientId ID of the recipient
    /// @return Status of the recipient
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return InternalRecipientStatus(_getUintRecipientStatus(_recipientId));
    }

    /// @notice Get recipient status
    /// @dev This will return the 'RecipientStatus' of the recipient, the 'RecipientStatus' is used at the strategy
    ///      level and is different from the 'InternalRecipientStatus' which is used at the protocol level
    /// @param _recipientId ID of the recipient
    /// @return Status of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = InternalRecipientStatus(_getUintRecipientStatus(_recipientId));

        // If the 'internalStatus' is 'Appealed' we will return 'Pending' instead
        if (internalStatus == InternalRecipientStatus.Appealed) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Sets recipient statuses.
    /// @dev The statuses are stored in a bitmap of 4 bits for each recipient. The first 4 bits of the 256 bits represent
    ///      the status of the first recipient, the second 4 bits represent the status of the second recipient, and so on.
    ///      'msg.sender' must be a pool manager and the registration must be active.
    /// Statuses:
    /// - 0: none
    /// - 1: pending
    /// - 2: accepted
    /// - 3: rejected
    /// - 4: appealed
    /// @param statuses new statuses
    function reviewRecipients(ApplicationStatus[] memory statuses)
        external
        onlyActiveRegistration
        onlyPoolManager(msg.sender)
    {
        // Loop through the statuses and set the status
        for (uint256 i = 0; i < statuses.length;) {
            uint256 rowIndex = statuses[i].index;
            uint256 fullRow = statuses[i].statusRow;

            statusesBitMap[rowIndex] = fullRow;

            // Emit that the recipient status has been updated with the values
            emit RecipientStatusUpdated(rowIndex, fullRow, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Sets the start and end dates.
    /// @dev The timestamps are in milliseconds for the start and end times. The 'msg.sender' must be a pool manager.
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
        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);

        // Set the updated timestamps
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// @notice Withdraw funds from pool
    /// @dev This can only be called after the allocation has ended and 30 days have passed. If the
    ///      '_amount' is greater than the pool amount or if 'msg.sender' is not a pool manager.
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

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        _transferAmount(pool.token, msg.sender, _amount);
    }

    /// ==================================
    /// ============ Merkle ==============
    /// ==================================

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata.
    /// @dev This can only be called after the allocation has ended and 'msg.sender' must be a pool manager and allocation must have ended.
    /// @param _merkleRoot The merkle root of the distribution
    /// @param _distributionMetadata The metadata of the distribution
    function updateDistribution(bytes32 _merkleRoot, Metadata memory _distributionMetadata)
        external
        onlyAfterAllocation
        onlyPoolManager(msg.sender)
    {
        // If the distribution has already started this will revert, you can only
        // update the distribution before it has started
        if (distributionStarted) {
            revert INVALID();
        }

        merkleRoot = _merkleRoot;
        distributionMetadata = _distributionMetadata;

        // Emit that the distribution has been updated
        emit DistributionUpdated(merkleRoot, distributionMetadata);
    }

    /// @notice Checks if distribution is set.
    /// @return Whether the distribution is set or not
    function isDistributionSet() external view returns (bool) {
        return merkleRoot != "";
    }

    /// @notice Utility function to check if distribution is done.
    /// @param _index index of the distribution
    /// @return Whether the distribution is completed or not
    function hasBeenDistributed(uint256 _index) external view returns (bool) {
        return _hasBeenDistributed(_index);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if address is elgible allocator.
    /// @return Always returns true for this strategy
    function _isValidAllocator(address) internal pure override returns (bool) {
        return true;
    }

    /// @notice Checks if the timestamps are valid.
    /// @dev This will revert if any of the timestamps are invalid. This is determined by the strategy
    /// and may vary from strategy to strategy. Checks if '_registrationStartTime' is less than the
    /// current 'block.timestamp' or if '_registrationStartTime' is greater than the '_registrationEndTime'
    /// or if '_registrationStartTime' is greater than the '_allocationStartTime' or if '_registrationEndTime'
    /// is greater than the '_allocationEndTime' or if '_allocationStartTime' is greater than the '_allocationEndTime'.
    /// If any of these conditions are true, this will revert.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
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

    /// @notice Checks whether a pool is active or not.
    /// @dev This will return true if the current 'block timestamp' is greater than or equal to the
    /// 'registrationStartTime' and less than or equal to the 'registrationEndTime'.
    /// @return Whether the pool is active or not
    function _isPoolActive() internal view override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Submit recipient to pool and set their status.
    /// @param _data The data to be decoded.
    /// @custom:data if 'useRegistryAnchor' is 'true' (address recipientId, address recipientAddress, Metadata metadata)
    /// @custom:data if 'useRegistryAnchor' is 'false' (address recipientAddress, address registryAnchor, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The ID of the recipient
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

            // If the sender is not a profile member this will revert
            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));

            // Set this to 'true' if the registry anchor is not the zero address
            isUsingRegistryAnchor = registryAnchor != address(0);

            // If using the 'registryAnchor' we set the 'recipientId' to the 'registryAnchor', otherwise we set it to the 'msg.sender'
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

            // Checks if the '_sender' is a member of the profile 'anchor' being used and reverts if not
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        // If the metadata is required and the metadata is invalid this will revert
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // If the recipient address is the zero address this will revert
        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        // Get the recipient
        Recipient storage recipient = _recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = useRegistryAnchor ? true : isUsingRegistryAnchor;

        uint8 currentStatus = _getUintRecipientStatus(recipientId);

        if (currentStatus == uint8(InternalRecipientStatus.None)) {
            // recipient registering new application
            recipientToStatusIndexes[recipientId] = recipientsCounter;
            _setRecipientStatus(recipientId, uint8(InternalRecipientStatus.Pending));

            bytes memory extendedData = abi.encode(_data, recipientsCounter);
            emit Registered(recipientId, extendedData, _sender);

            recipientsCounter++;
        } else {
            if (currentStatus == uint8(InternalRecipientStatus.Accepted)) {
                // recipient updating accepted application
                _setRecipientStatus(recipientId, uint8(InternalRecipientStatus.Pending));
            } else if (currentStatus == uint8(InternalRecipientStatus.Rejected)) {
                // recipient updating rejected application
                _setRecipientStatus(recipientId, uint8(InternalRecipientStatus.Appealed));
            }
            emit UpdatedRegistration(recipientId, _data, _sender, _getUintRecipientStatus(recipientId));
        }
    }

    /// @notice Distribute funds to recipients.
    /// @dev 'distributionStarted' will be set to 'true' when called. Only the pool manager can call.
    /// @param _data The data to be decoded
    /// @custom:data '(Distribution[] distributions)'
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (!distributionStarted) {
            distributionStarted = true;
        }

        // Decode the '_data' to get the distributions
        Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
        uint256 length = distributions.length;

        // Loop through the distributions and distribute the funds
        for (uint256 i = 0; i < length;) {
            _distributeSingle(distributions[i]);
            unchecked {
                i++;
            }
        }

        // Emit that the batch payout was successful
        emit BatchPayoutSuccessful(_sender);
    }

    /// @notice Allocate tokens to recipient.
    /// @dev This can only be called during the allocation period.
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, uint256 amount, address token)
    /// @param _sender The sender of the transaction
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActiveAllocation
    {
        // Decode the '_data' to get the recipientId, amount and token
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));

        // If the recipient status is not 'Accepted' this will revert, the recipient must be accepted through registration
        if (InternalRecipientStatus(_getUintRecipientStatus(recipientId)) != InternalRecipientStatus.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        // The token must be in the allowed token list and not be native token or zero address
        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        // If the token is native, the amount must be equal to the value sent, otherwise it reverts
        if (msg.value > 0 && token != NATIVE || token == NATIVE && msg.value != amount) {
            revert INVALID();
        }

        _onAllocate(recipientId, amount, token, _sender);

        // Emit that the amount has been allocated to the recipient by the sender
        emit Allocated(recipientId, amount, token, _sender);
    }

    /// @notice Custom allocate logic
    /// @param _recipientId Id of the recipient
    /// @param _amount Amount of tokens to be distributed
    /// @param _token Address of the token
    /// @param _sender The sender of the transaction
    function _onAllocate(address _recipientId, uint256 _amount, address _token, address _sender) internal virtual;

    /// @notice Check if sender is profile owner or member.
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return Whether the '_sender' is a profile member or not
    function _isProfileMember(address _anchor, address _sender) internal view virtual returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient details.
    /// @param _recipientId Id of the recipient
    /// @return Recipient details
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return _recipients[_recipientId];
    }

    /// @notice Returns the payout summary for the accepted recipient.
    /// @param _data The data to be decoded
    /// @custom:data '(Distribution)'
    /// @return 'PayoutSummary' for a recipient
    function _getPayout(address, bytes memory _data) internal view override returns (PayoutSummary memory) {
        // Decode the '_data' to get the distribution
        Distribution memory distribution = abi.decode(_data, (Distribution));

        uint256 index = distribution.index;
        address recipientId = distribution.recipientId;
        uint256 amount = distribution.amount;
        bytes32[] memory merkleProof = distribution.merkleProof;

        address recipientAddress = _getRecipient(recipientId).recipientAddress;

        // Validate the distribution
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            // Return a 'PayoutSummary' with the 'recipientAddress' and 'amount'
            return PayoutSummary(recipientAddress, amount);
        }

        // If the distribution is not valid, return a payout summary with the amount set to zero
        return PayoutSummary(recipientAddress, 0);
    }

    /// @notice Validate the distribution for the payout.
    /// @param _index index of the distribution
    /// @param _recipientId Id of the recipient
    /// @param _recipientAddress Address of the recipient
    /// @param _amount Amount of tokens to be distributed
    /// @param _merkleProof Merkle proof of the distribution
    /// @return Whether the distribution is valid or not
    function _validateDistribution(
        uint256 _index,
        address _recipientId,
        address _recipientAddress,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) internal view returns (bool) {
        // If the '_index' has been distributed this will return 'false'
        if (_hasBeenDistributed(_index)) {
            return false;
        }

        // Generate the node that will be verified in the 'merkleRoot'
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _recipientId, _recipientAddress, _amount))));

        // If the node is not verified in the 'merkleRoot' this will return 'false'
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            return false;
        }

        // Return 'true', the distribution is valid at this point
        return true;
    }

    /// @notice Check if the distribution has been distributed.
    /// @param _index index of the distribution
    /// @return Whether the distribution has been distributed or not
    function _hasBeenDistributed(uint256 _index) internal view returns (bool) {
        // Get the word index by dividing the '_index' by 256
        uint256 distributedWordIndex = _index / 256;

        // Get the bit index by getting the remainder of the '_index' divided by 256
        uint256 distributedBitIndex = _index % 256;

        // Get the word from the 'distributedBitMap' using the 'distributedWordIndex'
        uint256 distributedWord = distributedBitMap[distributedWordIndex];

        // Get the mask by shifting 1 to the left of the 'distributedBitIndex'
        uint256 mask = (1 << distributedBitIndex);

        // Return 'true' if the 'distributedWord' and 'mask' are equal to the 'mask'
        return distributedWord & mask == mask;
    }

    /// @notice Mark distribution as done.
    /// @param _index index of the distribution
    function _setDistributed(uint256 _index) private {
        // Get the word index by dividing the '_index' by 256
        uint256 distributedWordIndex = _index / 256;

        // Get the bit index by getting the remainder of the '_index' divided by 256
        uint256 distributedBitIndex = _index % 256;

        // Set the bit in the 'distributedBitMap' shifting 1 to the left of the 'distributedBitIndex'
        distributedBitMap[distributedWordIndex] |= (1 << distributedBitIndex);
    }

    /// @notice Distribute funds to recipient.
    /// @param _distribution Distribution to be distributed
    function _distributeSingle(Distribution memory _distribution) private {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId;
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        address recipientAddress = _recipients[recipientId].recipientAddress;

        // Validate the distribution and transfer the funds to the recipient, otherwise revert if not valid
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            // Set the distribution as distributed
            _setDistributed(index);

            // Update the pool amount
            poolAmount -= amount;

            // Transfer the amount to the recipient
            _transferAmount(pool.token, payable(recipientAddress), amount);

            // Emit that the funds have been distributed to the recipient
            emit FundsDistributed(amount, recipientAddress, pool.token, recipientId);
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }
    }

    /// @notice Set the recipient status.
    /// @param _recipientId ID of the recipient
    /// @param _status Status of the recipient
    function _setRecipientStatus(address _recipientId, uint256 _status) internal {
        // Get the row index, column index and current row
        (uint256 rowIndex, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);

        // Calculate the 'newRow'
        uint256 newRow = currentRow & ~(15 << colIndex);

        // Add the status to the mapping
        statusesBitMap[rowIndex] = newRow | (_status << colIndex);
    }

    /// @notice Get recipient status
    /// @param _recipientId ID of the recipient
    /// @return status status of the recipient
    function _getUintRecipientStatus(address _recipientId) internal view returns (uint8 status) {
        // Get the column index and current row
        (, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);

        // Get the status from the 'currentRow' shifting by the 'colIndex'
        status = uint8((currentRow >> colIndex) & 15);

        // Return the status
        return status;
    }

    /// @notice Get recipient status 'rowIndex', 'colIndex' and 'currentRow'.
    /// @param _recipientId ID of the recipient
    /// @return (rowIndex, colIndex, currentRow)
    function _getStatusRowColumn(address _recipientId) internal view returns (uint256, uint256, uint256) {
        uint256 recipientIndex = recipientToStatusIndexes[_recipientId];

        uint256 rowIndex = recipientIndex / 64; // 256 / 4
        uint256 colIndex = (recipientIndex % 64) * 4;

        return (rowIndex, colIndex, statusesBitMap[rowIndex]);
    }

    /// @notice Contract should be able to receive ETH
    receive() external payable {}
}
