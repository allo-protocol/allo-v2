// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
// Interfaces
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

// Timelock
import {TokenTimelock} from "openzeppelin-contracts/contracts/token/ERC20/utils/TokenTimelock.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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

/// @title LTIP Simple Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>, @bitbeckers
/// @notice Strategy for Long-Term Incentive Programs (LTIP) allocation with distribution vested over time. The simple strategy retains the funds in the round untill the period has expired
contract LTIPSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the recipients.
    struct Recipient {
        address recipientAddress;
        uint256 allocationAmount;
        Status recipientStatus;
        Metadata metadata;
    }

    /// @notice Pointer for the vesting plan.
    struct VestingPlan {
        address vestingContract;
        uint256 tokenId;
    }

    /// @notice The parameters used to initialize the strategy
    struct InitializeParams {
        // slot 0
        bool registryGating;
        bool metadataRequired;
        // slot 1
        uint256 votingThreshold;
        // slot 2
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 reviewStartTime;
        uint64 reviewEndTime;
        // slot 3
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint64 distributionStartTime;
        uint64 distributionEndTime;
        // slot 4
        uint64 vestingPeriod;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when the application is cancelled. Cancelled applicants cannot reapply.
    error APPLICATION_CANCELLED();

    /// @notice Thrown when the recipient already has allocation.
    error ALREADY_VESTED();

    /// @notice Thrown when the review period has ended.
    error REVIEW_NOT_ACTIVE();

    /// @notice Thrown when the recipient doesn't have enough votes for fund distribution.
    error INSUFFICIENT_VOTES();

    /// @notice Thrown when the rounds timestamps are configured incorrectly.
    error INVALID_TIMESTAMPS(string reason);

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId Id of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when a recipient is reviewed
    /// @param recipientId ID of the recipient
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event Reviewed(address indexed recipientId, Status status, address sender);

    /// @notice Emitted when a recipient status is updated
    /// @param recipientId ID of the recipient
    /// @param applicationId ID of the application
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event RecipientStatusUpdated(address indexed recipientId, uint256 applicationId, Status status, address sender);

    /// @notice Emitted when a recipient's application is canceled
    /// @param recipientId ID of the recipient
    /// @param sender The sender of the transaction
    event Canceled(address indexed recipientId, address sender);

    /// @notice Emitted when allocated funds are revoked and returned to the pool
    /// @param recipientId Id of the recipient
    /// @param sender The sender of the transaction
    event AllocationRevoked(address indexed recipientId, address sender);

    /// @notice Emitted when a vote is casted by an approved allocator
    /// @param recipientId The recipient that was voted for
    /// @param voter The allocator that casted the vote
    event Voted(address indexed recipientId, address voter);

    /// @notice Emitted when a vesting plan is created for a recipient
    /// @param vestingContract The address of the vesting contract
    /// @param tokenId The token id of the vesting contract (e.g. Hedgey NFT ID)
    event VestingPlanCreated(address indexed recipientId, address vestingContract, uint256 tokenId);

    /// @notice Emitted when the pool timestamps are updated
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param distributionStartTime The start time for the distribution
    /// @param distributionEndTime The end time for the distribution
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param reviewStartTime The start time for the application review
    /// @param reviewEndTime The end time for the application review
    /// @param sender The sender of the transaction
    event TimestampsUpdated(
        uint64 allocationStartTime,
        uint64 allocationEndTime,
        uint64 distributionStartTime,
        uint64 distributionEndTime,
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 reviewStartTime,
        uint64 reviewEndTime,
        address sender
    );

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public registryGating;

    /// @notice Flag to indicate whether metadata is required or not.
    bool public metadataRequired;

    /// @notice The voting threshold for a recipient to be accepted
    uint256 public votingThreshold;

    /// @notice Start time for registration
    uint64 public registrationStartTime;

    /// @notice End time for registration
    uint64 public registrationEndTime;

    /// @notice Start time for review
    uint64 public reviewStartTime;

    /// @notice End time for registration
    uint64 public reviewEndTime;

    /// @notice Start time for allocation
    uint64 public allocationStartTime;

    /// @notice End time for allocation
    uint64 public allocationEndTime;

    /// @notice Start time for distribution
    uint64 public distributionStartTime;

    /// @notice End time for distribution
    uint64 public distributionEndTime;

    /// @notice Vesting period in seconds;
    uint64 public vestingPeriod;

    /// @notice The registry contract interface.
    IRegistry private _registry;

    /// @notice Internal collection of recipients
    address[] private _recipientIds;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) internal _recipients;

    /// @notice This maps accepted recipients to their vesting plans
    /// @dev 'recipientId' to 'VestingPlan'
    mapping(address => VestingPlan) internal _vestingPlans;

    /// @notice This maps the allocator to the recipient they voted for
    /// @dev 'allocator' to 'recipientId'
    mapping(address => address) public votedFor;

    /// @notice This maps the recipient to the number of votes they have received
    /// @dev 'recipientId' to 'votes'
    mapping(address => uint256) public votes;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the allocation is active
    /// @dev This will revert if the allocation has not started or if the allocation has ended.
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if the registration is active
    /// @dev This will revert if the registration has not started or if the registration has ended.
    modifier onlyActiveRegistration() {
        _checkOnlyActiveRegistration();
        _;
    }

    /// @notice Modifier to check if the review is active
    /// @dev Reverts if the review is not active
    modifier onlyActiveReview() {
        _checkOnlyActiveReview();
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the LTIP Simple Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool registryGating, bool metadataRequired, uint256 votingThreshold, uint64 registrationStartTime, uint64 registrationEndTime, uint64 reviewStartTime, uint64 reviewEndTime, uint64 allocationStartTime, uint64 allocationEndTime, uint64 distributionStartTime, uint64 distributionEndTime, uint64 vestingPeriod)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams) = abi.decode(_data, (InitializeParams));
        __LTIPSimpleStrategy_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __LTIPSimpleStrategy_init(uint256 _poolId, InitializeParams memory _initializeParams) internal {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        if (_initializeParams.votingThreshold == 0) revert INVALID();
        if (_initializeParams.vestingPeriod == 0) revert INVALID();

        _isPoolTimestampValid(
            _initializeParams.allocationStartTime,
            _initializeParams.allocationEndTime,
            _initializeParams.distributionStartTime,
            _initializeParams.distributionEndTime,
            _initializeParams.registrationStartTime,
            _initializeParams.registrationStartTime,
            _initializeParams.reviewStartTime,
            _initializeParams.reviewEndTime
        );

        // Set the strategy specific variables
        registryGating = _initializeParams.registryGating;
        metadataRequired = _initializeParams.metadataRequired;
        votingThreshold = _initializeParams.votingThreshold;
        registrationStartTime = _initializeParams.registrationStartTime;
        registrationEndTime = _initializeParams.registrationEndTime;
        reviewStartTime = _initializeParams.reviewStartTime;
        reviewEndTime = _initializeParams.reviewEndTime;
        allocationStartTime = _initializeParams.allocationStartTime;
        allocationEndTime = _initializeParams.allocationEndTime;
        distributionStartTime = _initializeParams.distributionStartTime;
        distributionEndTime = _initializeParams.distributionEndTime;
        vestingPeriod = _initializeParams.vestingPeriod;

        _registry = allo.getRegistry();
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return Recipient Returns the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _recipients[_recipientId];
    }

    /// @notice Get the vesting plan
    /// @param _recipientId ID of the recipient
    /// @return VestingPlan Returns the vesting plan
    function getVestingPlan(address _recipientId) external view returns (VestingPlan memory) {
        return _vestingPlans[_recipientId];
    }

    /// @notice Return the payout for acceptedRecipientId
    function getPayouts(address[] memory __recipientIds, bytes[] memory)
        external
        view
        override
        returns (PayoutSummary[] memory)
    {
        // TODO add vested allocation info to payouts
        uint256 recipientLength = __recipientIds.length;

        PayoutSummary[] memory payouts = new PayoutSummary[](recipientLength);
        for (uint256 i; i < recipientLength;) {
            payouts[i] = _getPayout(_recipientIds[i], "");
            unchecked {
                ++i;
            }
        }

        return payouts;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Review recipient(s) application(s)
    /// @dev You can review multiple recipients at once or just one. This can only be called by a pool manager and
    ///      only during active registration.
    /// @param __recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata __recipientIds, Status[] calldata _recipientStatuses)
        external
        virtual
        onlyPoolManager(msg.sender)
        onlyActiveReview
    {
        // make sure the arrays are the same length
        uint256 recipientLength = __recipientIds.length;
        if (recipientLength != _recipientStatuses.length) revert INVALID();

        for (uint256 i; i < recipientLength;) {
            Status recipientStatus = _recipientStatuses[i];
            address recipientId = __recipientIds[i];
            Recipient storage recipient = _recipients[recipientId];

            // only pending applications can be updated
            // and the new status can only be Accepted or Rejected
            if (
                recipient.recipientStatus != Status.Pending
                    || (recipientStatus != Status.Accepted && recipientStatus != Status.Rejected)
            ) {
                revert RECIPIENT_ERROR(recipientId);
            }
            recipient.recipientStatus = recipientStatus;

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Cancel (remove) recipient(s) application(s)
    /// @dev You can remove multiple recipients at once or just one.
    /// @param __recipientIds Ids of the recipients
    function cancelRecipients(address[] calldata __recipientIds) external virtual onlyPoolManager(msg.sender) {
        uint256 recipientLength = __recipientIds.length;

        for (uint256 i; i < recipientLength;) {
            address recipientId = __recipientIds[i];
            Recipient storage recipient = _recipients[recipientId];

            // if the status is none or canceled then revert
            if (recipient.recipientStatus == Status.None || recipient.recipientStatus == Status.Canceled) {
                revert RECIPIENT_ERROR(recipientId);
            }

            recipient.recipientStatus = Status.Canceled;

            emit Canceled(recipientId, msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Withdraw the tokens from the pool
    /// @dev Callable by the pool manager
    /// @param _token The token to withdraw
    function withdraw(address _token) external virtual onlyPoolManager(msg.sender) {
        uint256 amount = _getBalance(_token, address(this));

        _transferAmount(_token, msg.sender, amount);
    }

    /// @notice Sets the start and end dates.
    /// @dev The timestamps are in seconds for the start and end times. The 'msg.sender' must be a pool manager.
    ///      Emits a 'TimestampsUpdated()' event.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    function updatePoolTimestamps(
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        uint64 _distributionStartTime,
        uint64 _distributionEndTime,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _reviewStartTime,
        uint64 _reviewEndTime
    ) external onlyPoolManager(msg.sender) {
        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(
            _allocationStartTime,
            _allocationEndTime,
            _distributionStartTime,
            _distributionEndTime,
            _registrationStartTime,
            _registrationEndTime,
            _reviewStartTime,
            _reviewEndTime
        );

        // Set the updated timestamps
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        reviewStartTime = _reviewStartTime;
        reviewEndTime = _reviewEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;
        distributionStartTime = _distributionStartTime;
        distributionEndTime = _distributionEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(
            allocationStartTime,
            allocationEndTime,
            distributionStartTime,
            distributionEndTime,
            registrationStartTime,
            registrationEndTime,
            reviewStartTime,
            reviewEndTime,
            msg.sender
        );
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit a proposal to LTIP pool
    /// @dev Emits a 'Registered()' event
    /// @param _data The data to be decoded
    ///     - If registryGating is true, then the data is encoded as (address recipientId, address recipientAddress, uint256 allocationAmount, Metadata metadata)
    ///     - If registryGating is false, then the data is encoded as (address recipientAddress, address registryAnchor, uitn256, allocationAmount, Metadata metadata)
    /// @custom:data-registry (address recipientId, address recipientAddress, uint256 allocationAmount, Metadata metadata)
    /// @custom:data-no-registry (address recipientAddress, address registryAnchor, uint256 allocationAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The id of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        bool isUsingRegistryAnchor;
        address recipientAddress;
        address registryAnchor;
        uint256 allocationAmount;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, allocationAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            // when registry gating is enabled, the recipientId must be a profile member
            if (!_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        } else {
            (recipientAddress, registryAnchor, allocationAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

            // when using registry anchor, the ID of the recipient must be a profile member
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        }

        // Check if the metadata is required and if it is, check if it is valid, otherwise revert
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // If the recipient address is the zero address this will revert
        if (recipientAddress == address(0)) revert RECIPIENT_ERROR(recipientId);

        Recipient storage recipient = _recipients[recipientId];
        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.allocationAmount = allocationAmount;
        recipient.metadata = metadata;

        if (recipient.recipientStatus == Status.None) {
            recipient.recipientStatus = Status.Pending;
            // If the recipient status is 'None' add the recipient to the '_recipientIds' array
            _recipientIds.push(recipientId);
            emit Registered(recipientId, _data, _sender);
        } else {
            /// if the recipient already exist we don't need to update their status to pending
            emit UpdatedRegistration(recipientId, _data, _sender);
        }
    }

    /// @notice Allocate (delegated) voting power to a recipient. In the simple strategy, every authorized voter has 1 vote.
    /// @dev '_sender' must be allowed to allocate.
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActiveAllocation
    {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();
        // Decode the '_data'
        address recipientId = abi.decode(_data, (address));
        Recipient storage recipient = _recipients[recipientId];

        if (recipient.recipientStatus != Status.Accepted) revert RECIPIENT_NOT_ACCEPTED();

        // Check if the allocator has already casted the vote
        address voteCastedTo = votedFor[_sender];
        if (voteCastedTo != address(0)) {
            // remove the old vote to allow recasting of vote
            votes[voteCastedTo] -= 1;
        }

        // Increment the votes for the recipient
        votes[recipientId] += 1;
        // Update the votedFor mapping
        votedFor[_sender] = recipientId;

        // Emit the event
        emit Voted(recipientId, _sender);

        if (votes[recipientId] >= votingThreshold) {
            emit Allocated(recipientId, recipient.allocationAmount, allo.getPool(poolId).token, _sender);
        }
    }

    /// @notice Create a vesting plan for the recipient
    /// @param recipientId ID of the recipient
    /// @param recipientAddress Address of the recipient
    /// @param _token The token to be vested
    /// @param _amount The amount to be vested
    function _vestAmount(address recipientId, address recipientAddress, address _token, uint256 _amount)
        internal
        virtual
    {
        TokenTimelock vestingContract =
            new TokenTimelock(IERC20(_token), recipientAddress, block.timestamp + vestingPeriod);

        _transferAmount(_token, address(vestingContract), _amount);

        _vestingPlans[recipientId] = VestingPlan(address(vestingContract), 0);

        emit VestingPlanCreated(recipientId, address(vestingContract), 0);
    }

    /// @notice Distribute the upcoming milestone to acceptedRecipientId.
    /// @dev As allocation determines the acceptance, anybody should be able to distribute.
    /// @param _sender The sender of the distribution.
    function _distribute(address[] memory __recipientIds, bytes memory, address _sender) internal virtual override {
        IAllo.Pool memory pool = allo.getPool(poolId);

        uint256 recipientLength = __recipientIds.length;

        for (uint256 i; i < recipientLength;) {
            address recipientId = __recipientIds[i];

            Recipient memory recipient = _recipients[recipientId];

            // Check if the recipient is accepted

            if (recipient.recipientStatus != Status.Accepted) revert RECIPIENT_NOT_ACCEPTED();

            if (votes[recipientId] < votingThreshold) revert INSUFFICIENT_VOTES();

            if (_vestingPlans[recipientId].vestingContract != address(0)) revert ALREADY_VESTED();

            // Get the pool, subtract the amount and transfer to the recipient
            poolAmount -= recipient.allocationAmount;

            _vestAmount(recipientId, recipient.recipientAddress, pool.token, recipient.allocationAmount);

            // Emit events for the milestone and the distribution
            emit Distributed(recipientId, recipient.recipientAddress, recipient.allocationAmount, _sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks if the pool is active.
    /// @dev Used by the strategy implementation.
    /// @return 'true' if the pool is active, otherwise 'false'
    function _isPoolActive() internal view virtual override returns (bool) {
        return block.timestamp >= allocationStartTime && block.timestamp <= distributionEndTime;
    }

    function _isPoolTimestampValid(
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        uint64 _distributionStartTime,
        uint64 _distributionEndTime,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _reviewStartTime,
        uint64 _reviewEndTime
    ) internal view {
        if (block.timestamp > _registrationStartTime) {
            // Register timestamps must be in the future
            revert INVALID_TIMESTAMPS("block.timestamp > _registrationStartTime");
        }

        if (_allocationStartTime > _allocationEndTime) {
            // Start times must be before end times
            revert INVALID_TIMESTAMPS("_allocationStartTime > _allocationEndTime");
        }

        if (_distributionStartTime > _distributionEndTime) {
            // Start times must be before end times
            revert INVALID_TIMESTAMPS("_distributionStartTime > _distributionEndTime");
        }

        if (_registrationStartTime > _registrationEndTime) {
            // Start times must be before end times
            revert INVALID_TIMESTAMPS("_registrationStartTime > _registrationEndTime");
        }

        if (_reviewStartTime > _reviewEndTime) {
            // Start times must be before end times
            revert INVALID_TIMESTAMPS("_reviewStartTime > _reviewEndTime");
        }

        if (_registrationEndTime > _allocationEndTime) {
            // Some end times must be after other end times
            revert INVALID_TIMESTAMPS("_registrationEndTime > _allocationEndTime");
        }

        if (_allocationEndTime > _distributionEndTime) {
            // Some end times must be after other end times
            revert INVALID_TIMESTAMPS("_allocationEndTime > _distributionEndTime");
        }

        if (_reviewStartTime > _allocationEndTime) {
            // Some end times must be after other end times
            revert INVALID_TIMESTAMPS("_reviewStartTime > _allocationEndTime");
        }
    }

    /// @notice Check if sender is a profile owner or member.
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return 'true' if the sender is the owner or member of the profile, otherwise 'false'
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Checks if address is eligible allocator.
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        return _recipients[_recipientId].recipientStatus;
    }

    /// @notice Get the payout summary for the accepted recipient.
    /// @return Returns the payout summary for the accepted recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _recipients[_recipientId];
        return PayoutSummary(recipient.recipientAddress, recipient.allocationAmount);
    }

    /// @notice Checks if the registration is active and reverts if not.
    /// @dev This will revert if the registration has not started or if the registration has ended.
    function _checkOnlyActiveRegistration() internal view {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
    }

    /// @notice Checks if the allocation is active and reverts if not.
    /// @dev This will revert if the allocation has not started or if the allocation has ended.
    function _checkOnlyActiveAllocation() internal view {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the review period is active
    /// @dev Reverts if not active
    function _checkOnlyActiveReview() internal view virtual {
        if (block.timestamp < reviewStartTime || block.timestamp > reviewEndTime) revert REVIEW_NOT_ACTIVE();
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
