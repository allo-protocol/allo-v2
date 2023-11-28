// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
// Interfaces
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";

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

abstract contract MicroGrantsBaseStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the recipients.
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 requestedAmount;
        Status recipientStatus;
        Metadata metadata;
    }

    /// @notice Stores the details needed for initializing strategy
    struct InitializeParams {
        bool useRegistryAnchor;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 approvalThreshold;
        uint256 maxRequestedAmount;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when the pool manager attempts to the lower the requested amount
    error AMOUNT_TOO_LOW();

    /// @notice Thrown when the pool manager attempts to the increase the requested amount
    error EXCEEDING_MAX_AMOUNT();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the max requested amount is increased.
    /// @param maxRequestedAmount The new max requested amount
    event MaxRequestedAmountIncreased(uint256 maxRequestedAmount);

    /// @notice Emitted when the approval threshold is updated.
    /// @param approvalThreshold The new approval threshold
    event ApprovalThresholdUpdated(uint256 approvalThreshold);

    /// @notice Emitted when the timestamps are updated
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event TimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId Id of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when an allocation is made
    /// @param recipientId Id of the recipient
    /// @param status The status of the allocation
    /// @param sender The sender of the transaction
    event Allocated(address indexed recipientId, Status status, address sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public useRegistryAnchor;

    /// @notice The registry contract interface.
    IRegistry private _registry;

    /// @notice The timestamps in milliseconds for the allocation start and end time.
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice The max amount that can be requested by a recipient.
    uint256 public maxRequestedAmount;

    /// @notice The approval threshold for a recipient to be accepted.
    uint256 public approvalThreshold;

    /// @notice 'recipientId' => 'Recipient' struct.
    mapping(address => Recipient) internal _recipients;

    /// @notice Mapping to track if an allocator has voted/allocated to a recipient
    /// @dev 'allocator' => 'recipient Id' => 'bool'
    mapping(address => mapping(address => bool)) public allocated;

    /// @notice This maps the recipientId to the Status to the number of votes/allocations
    /// @dev 'recipientId' => 'Status' => 'uint256'
    mapping(address => mapping(Status => uint256)) public recipientAllocations;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the allocation is active
    /// @dev Reverts if the allocation is not active
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Micro Grants Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool useRegistryAnchor; uint64 allocationStartTime,
    ///    uint64 allocationEndTime, uint256 approvalThreshold, uint256 maxRequestedAmount)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams) = abi.decode(_data, (InitializeParams));
        __MicroGrants_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __MicroGrants_init(uint256 _poolId, InitializeParams memory _initializeParams) internal {
        // Initialize the BaseStrategy with the '_poolId'
        __BaseStrategy_init(_poolId);

        // Initialize required values
        useRegistryAnchor = _initializeParams.useRegistryAnchor;
        _registry = allo.getRegistry();

        _updatePoolTimestamps(_initializeParams.allocationStartTime, _initializeParams.allocationEndTime);
        _increaseMaxRequestedAmount(_initializeParams.maxRequestedAmount);
        _setApprovalThreshold(_initializeParams.approvalThreshold);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return Recipient Returns the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Returns the payout summary for the accepted recipient.
    /// @param _recipientId ID of the recipient
    /// @return 'PayoutSummary' for a recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _getRecipient(_recipientId);
        uint256 amount = recipient.requestedAmount;
        if (recipient.recipientStatus == Status.Accepted) {
            amount = 0;
        }
        return PayoutSummary(recipient.recipientAddress, amount);
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Update max requested amount
    /// @dev 'msg.sender' must be a pool manager to update the max requested amount.
    /// @param _maxRequestedAmount The max requested amount to be set
    function increaseMaxRequestedAmount(uint256 _maxRequestedAmount) external onlyPoolManager(msg.sender) {
        _increaseMaxRequestedAmount(_maxRequestedAmount);
    }

    /// @notice Update the approval threshold for recipient to be accepted
    /// @dev 'msg.sender' must be a pool manager to update the approval threshold.
    /// @param _approvalThreshold The approval threshold to be set
    function setApprovalThreshold(uint256 _approvalThreshold) external onlyPoolManager(msg.sender) {
        _setApprovalThreshold(_approvalThreshold);
    }

    /// @notice Sets the allocation start and end dates.
    /// @dev The timestamps are in milliseconds for the start and end times. The 'msg.sender' must be a pool manager.
    ///      Emits a 'TimestampsUpdated()' event.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)
        external
        onlyPoolManager(msg.sender)
    {
        _updatePoolTimestamps(_allocationStartTime, _allocationEndTime);
    }

    /// @notice Withdraw the tokens from the pool
    /// @dev Callable by the pool manager
    /// @param _token The token to withdraw
    function withdraw(address _token) external onlyPoolManager(msg.sender) onlyInactivePool {
        uint256 amount = _getBalance(_token, address(this));

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        _transferAmount(_token, msg.sender, amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Check if the allocation is active
    /// @dev Reverts if the allocation is not active
    function _checkOnlyActiveAllocation() internal view virtual {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Sets the allocation start and end dates.
    /// @dev The timestamps are in milliseconds for the start and end times.
    ///      Emits a 'TimestampsUpdated()' event.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _updatePoolTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) internal {
        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(_allocationStartTime, _allocationEndTime);

        // Set the updated timestamps
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(allocationStartTime, allocationEndTime, msg.sender);
    }

    /// @notice Checks if the timestamps are valid.
    /// @dev This will revert if any of the timestamps are invalid. This is determined by the strategy
    /// and may vary from strategy to strategy. Checks if '_allocationStartTime' is less than the
    /// current 'block.timestamp' or if '_allocationStartTime' is greater than the '_allocationEndTime'.
    /// If any of these conditions are true, this will revert.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _isPoolTimestampValid(uint64 _allocationStartTime, uint64 _allocationEndTime) internal view {
        if (block.timestamp > _allocationStartTime || _allocationStartTime > _allocationEndTime) {
            revert INVALID();
        }
    }

    /// @notice Update max requested amount
    /// @param _maxRequestedAmount The max requested amount to be set
    function _increaseMaxRequestedAmount(uint256 _maxRequestedAmount) internal {
        if (_maxRequestedAmount < maxRequestedAmount) {
            revert AMOUNT_TOO_LOW();
        }
        maxRequestedAmount = _maxRequestedAmount;
        emit MaxRequestedAmountIncreased(maxRequestedAmount);
    }

    /// @notice Sets the approval threshold for recipient to be accepted
    /// @param _approvalThreshold The approval threshold to be set
    function _setApprovalThreshold(uint256 _approvalThreshold) internal {
        approvalThreshold = _approvalThreshold;
        emit ApprovalThresholdUpdated(approvalThreshold);
    }

    /// @notice Checks whether a pool is active or not.
    /// @dev This will return true if the allocationEndTime is greater than the current block timestamp.
    /// @return 'true' if pool is active, otherwise 'false'
    function _isPoolActive() internal view override returns (bool) {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            return false;
        }

        return true;
    }

    /// @notice Register a recipient
    /// @param _data The data to be decoded
    /// @custom:data (address registryAnchor, address recipientAddress, uint256 requestedAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId Returns the recipient id
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        returns (address recipientId)
    {
        bool isUsingRegistryAnchor;
        address recipientAddress;
        address registryAnchor;
        uint256 requestedAmount;
        Metadata memory metadata;

        //  @custom:data (address registryAnchor, address recipientAddress, uint256 requestedAmount, Metadata metadata)
        (registryAnchor, recipientAddress, requestedAmount, metadata) =
            abi.decode(_data, (address, address, uint256, Metadata));

        // Check if the registry anchor is valid so we know whether to use it or not
        isUsingRegistryAnchor = useRegistryAnchor || registryAnchor != address(0);

        // Ternerary to set the recipient id based on whether or not we are using the 'registryAnchor' or '_sender'
        recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

        // Checks if the '_sender' is a member of the profile 'anchor' being used and reverts if not
        if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();

        // Check if metadata it is valid, otherwise revert
        if (bytes(metadata.pointer).length == 0 || metadata.protocol == 0) {
            revert INVALID_METADATA();
        }

        if (requestedAmount > maxRequestedAmount) {
            // If the requested amount is greater than the max requested amount, revert
            revert EXCEEDING_MAX_AMOUNT();
        } else if (requestedAmount == 0) {
            // If the requested amount is 0, set requested amount to the max requested amount
            requestedAmount = maxRequestedAmount;
        }

        // If the recipient address is the zero address this will revert
        if (recipientAddress == address(0)) revert RECIPIENT_ERROR(recipientId);

        // Get the recipient
        Recipient storage recipient = _recipients[recipientId];

        // check if recipient already has allocations
        if (
            recipientAllocations[recipientId][Status.Accepted] > 0
                || recipientAllocations[recipientId][Status.Rejected] > 0
        ) revert UNAUTHORIZED();

        if (recipient.recipientStatus == Status.None) {
            emit Registered(recipientId, _data, _sender);
        } else {
            emit UpdatedRegistration(recipientId, _data, _sender);
        }

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.useRegistryAnchor = isUsingRegistryAnchor;
        recipient.requestedAmount = requestedAmount;
        recipient.metadata = metadata;
        recipient.recipientStatus = Status.Pending;

        return recipientId;
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, Status status)
    /// @param _sender The sender of the transaction
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        (address recipientId, Status status) = abi.decode(_data, (address, Status));
        Recipient storage recipient = _recipients[recipientId];

        // Revert if allocator has already allocated to recipient or if recipient has already been accepted
        if (allocated[_sender][recipientId] || recipient.recipientStatus == Status.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        allocated[_sender][recipientId] = true;

        recipientAllocations[recipientId][status] += 1;

        emit Allocated(recipientId, status, _sender);

        if (recipientAllocations[recipientId][Status.Accepted] == approvalThreshold) {
            recipient.recipientStatus = Status.Accepted;

            IAllo.Pool memory pool = allo.getPool(poolId);
            uint256 amount = recipient.requestedAmount;

            poolAmount -= amount;

            _transferAmount(pool.token, recipient.recipientAddress, amount);

            emit Distributed(recipientId, recipient.recipientAddress, recipient.requestedAmount, _sender);
        }
    }

    /// @notice Not implemented
    function _distribute(address[] memory, bytes memory, address) internal virtual override {
        assert(false);
    }

    /// @notice Check if sender is a profile owner or member.
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return 'true' if the sender is the owner or member of the profile, otherwise 'false'
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient.
    /// @param _recipientId ID of the recipient
    /// @return recipient Returns the recipient information
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];

        if (block.timestamp > allocationEndTime && recipient.recipientStatus != Status.Accepted) {
            recipient.recipientStatus = Status.Rejected;
        }
    }

    /// @notice Contract should be able to receive NATIVE
    receive() external payable {}
}
