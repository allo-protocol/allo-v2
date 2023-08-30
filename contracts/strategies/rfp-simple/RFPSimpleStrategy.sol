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

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣮⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡏⠘⣿⣿⣿⣷⡀          ⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠹⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠁⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡄⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣴⣿⣿⣿⡿⠋⠁⠀⠀⠀⠉⠻⣿⣿⣿⣿⡆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⠄⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⢀⢀⢀⢀⢀⢀⢀⢀⠈⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣧⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠟⠿⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡿⠁⠀          ⠀⠀⢿⣿⣿⣿⣧⠀ ⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⣀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠋⠋⠋⠋⠋⠛⠙⠋⠛⠙⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃            ⠀     ⠟⠿⠟⠿⠆⠀⠸⠿⠿⠻⠗⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠀⠙⠛⠿⢿⢿⡿⡿⡿⠟⠏⠃⠀⠀⠀⠀⠀
//                    allo.gitcoin.co


/// @title RFP Simple Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Strategy for Request for Proposal (RFP) allocation with milestone submission and management.
contract RFPSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the recipients.
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 proposalBid;
        RecipientStatus recipientStatus;
    }

    /// @notice Stores the details of the milestone
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        RecipientStatus milestoneStatus;
    }

    struct InitializeParams {
        uint256 maxBid;
        bool useRegistryAnchor;
        bool metadataRequired;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Thrown when the milestone is invalid
    error INVALID_MILESTONE();

    /// @notice Thrown when the milestone is already accepted
    error MILESTONE_ALREADY_ACCEPTED();

    /// @notice Thrown when the proposal bid exceeds maximum bid
    error EXCEEDING_MAX_BID();

    /// @notice Thrown when the milestone are already approved and cannot be changed
    error MILESTONES_ALREADY_SET();

    /// @notice Thrown when the pool manager attempts to the lower the max bid
    error AMOUNT_TOO_LOW();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the maximum bid is increased.
    /// @param maxBid The mew maximum bid
    event MaxBidIncreased(uint256 maxBid);

    /// @notice Emitted when a milestone is submitted.
    /// @param milestoneId Id of the milestone
    event MilstoneSubmitted(uint256 milestoneId);

    /// @notice Emitted for the status change of a milestone.
    event MilestoneStatusChanged(uint256 milestoneId, RecipientStatus status);

    /// @notice Emitted when milestones are set.
    event MilestonesSet();

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public useRegistryAnchor;

    /// @notice Flag to indicate whether metadata is required or not.
    bool public metadataRequired;

    /// @notice The accepted recipient who can submit milestones.
    address public acceptedRecipientId;

    /// @notice The registry contract interface.
    IRegistry private _registry;

    /// @notice The maximum bid for the RFP pool.
    uint256 public maxBid;

    /// @notice The upcoming milestone which is to be paid.
    uint256 public upcomingMilestone;

    /// @notice Internal collection of recipients
    address[] private _recipientIds;

    /// @notice Collection of milestones submitted by the 'acceptedRecipientId'
    Milestone[] public milestones;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) internal _recipients;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the RFP Simple Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (uint256 _maxBid, bool registryGating, bool metadataRequired)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams) = abi.decode(_data, (InitializeParams));
        __RFPSimpleStrategy_init(_poolId, initializeParams);
    }


    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __RFPSimpleStrategy_init(uint256 _poolId, InitializeParams memory _initializeParams)
        internal
    {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        // Set the strategy specific variables
        useRegistryAnchor = _initializeParams.useRegistryAnchor;
        metadataRequired = _initializeParams.metadataRequired;
        _registry = allo.getRegistry();
        _increaseMaxBid(_initializeParams.maxBid);

        // Set the pool to active - this is required for the strategy to work and distribute funds
        // NOTE: There may be some cases where you may want to not set this here, but will be strategy specific
        _setPoolActive(true);
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

    /// @notice Get recipient status
    /// @dev The global 'RecipientStatus' is used at the protocol level and most strategies may want to
    ///      add a additional InternalRecipientStatus to track the status of the recipient and map back to
    ///      the global 'RecipientStatus'
    /// @param _recipientId ID of the recipient
    /// @return RecipientStatus Returns the global recipient status
    function _getRecipientStatus(address _recipientId) internal view override returns (RecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Return the payout for acceptedRecipientId
    function getPayouts(address[] memory, bytes[] memory) external view override returns (PayoutSummary[] memory) {
        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        payouts[0] = _getPayout(acceptedRecipientId, "");

        return payouts;
    }

    /// @notice Get the milestone
    /// @param _milestoneId ID of the milestone
    /// @return Milestone[] Returns the milestones
    function getMilestone(uint256 _milestoneId) external view returns (Milestone memory) {
        return milestones[_milestoneId];
    }

    /// @notice Get the status of the milestone
    /// @dev This is used to check the status of the milestone of an recipient and is strategy specific
    /// @param _milestoneId ID of the milestone
    /// @return RecipientStatus Returns the status of the milestone using the 'RecipientStatus' enum
    function getMilestoneStatus(uint256 _milestoneId) external view returns (RecipientStatus) {
        return milestones[_milestoneId].milestoneStatus;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Closes the pool by setting the pool to inactive
    /// @dev 'msg.sender' must be a pool manager to close the pool. Emits a 'PoolActive()' event.
    /// @param _flag The flag to set the pool to active or inactive
    function setPoolActive(bool _flag) external {
        _setPoolActive(_flag);
        emit PoolActive(_flag);
    }

    /// @notice Set the milestones for the acceptedRecipientId.
    /// @param _milestones The milestones to be set
    function setMilestones(Milestone[] memory _milestones) external onlyPoolManager(msg.sender) {
        if (upcomingMilestone != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        uint256 totalAmountPercentage;

        uint256 milestonesLength = _milestones.length;
        for (uint256 i = 0; i < milestonesLength;) {
            totalAmountPercentage += _milestones[i].amountPercentage;
            milestones.push(_milestones[i]);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONE();
        }

        emit MilestonesSet();
    }

    /// @notice Submit milestone by the acceptedRecipientId.
    /// @dev 'msg.sender' must be the 'acceptedRecipientId' and must be a member
    ///      of a 'Profile' to sumbit a milestone. Emits a 'MilestonesSubmitted()' event.
    /// @param _metadata The proof of work
    function submitUpcomingMilestone(Metadata calldata _metadata) external {
        if (acceptedRecipientId != msg.sender && !_isProfileMember(acceptedRecipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        if (upcomingMilestone >= milestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = milestones[upcomingMilestone];
        milestone.metadata = _metadata;
        milestone.milestoneStatus = RecipientStatus.Pending;

        emit MilstoneSubmitted(upcomingMilestone);
    }

    /// @notice Update max bid for RFP pool
    /// @param _maxBid The max bid to be set
    function increaseMaxBid(uint256 _maxBid) external onlyPoolManager(msg.sender) {
        _increaseMaxBid(_maxBid);
    }

    /// @notice Reject pending milestone submmited by the acceptedRecipientId.
    /// @dev 'msg.sender' must be a pool manager to reject a milestone. Emits a 'MilestoneRejected()' event.
    /// @param _milestoneId ID of the milestone
    function rejectMilestone(uint256 _milestoneId) external onlyPoolManager(msg.sender) {
        if (milestones[_milestoneId].milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        milestones[_milestoneId].milestoneStatus = RecipientStatus.Rejected;
        emit MilestoneStatusChanged(_milestoneId, RecipientStatus.Rejected);
    }

    /// @notice Withdraw funds from pool.
    /// @dev 'msg.sender' must be a pool manager to withdraw funds.
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) onlyInactivePool {
        poolAmount -= _amount;
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Submit a proposal to RFP pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        returns (address recipientId)
    {
        bool isUsingRegistryAnchor;
        address recipientAddress;
        address registryAnchor;
        uint256 proposalBid;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (useRegistryAnchor) {
            (recipientId, proposalBid, metadata) = abi.decode(_data, (address, uint256, Metadata));

            // If the sender is not a profile member this will revert
            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, proposalBid, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

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

        if (proposalBid > maxBid) {
            // If the proposal bid is greater than the max bid this will revert
            revert EXCEEDING_MAX_BID();
        } else if (proposalBid == 0) {
            // If the proposal bid is 0, set it to the max bid
            proposalBid = maxBid;
        }

        // If the recipient address is the zero address this will revert
        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        // Get the recipient
        Recipient storage recipient = _recipients[recipientId];

        // Ensure the recipient is not already registered
        if (recipient.recipientStatus == RecipientStatus.None) {
            _recipients[recipientId] = recipient;
        }

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.useRegistryAnchor = isUsingRegistryAnchor ? true : recipient.useRegistryAnchor;
        recipient.proposalBid = proposalBid;
        recipient.recipientStatus = RecipientStatus.Pending;

        _recipientIds.push(recipientId);

        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Select recipient for RFP allocation
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActivePool
        onlyPoolManager(_sender)
    {
        acceptedRecipientId = abi.decode(_data, (address));

        // update status of acceptedRecipientId to accepted
        Recipient storage recipient = _recipients[acceptedRecipientId];

        if (acceptedRecipientId == address(0) || recipient.recipientStatus != RecipientStatus.Pending) {
            revert RECIPIENT_ERROR(acceptedRecipientId);
        }

        recipient.recipientStatus = RecipientStatus.Accepted;
        _setPoolActive(false);

        IAllo.Pool memory pool = allo.getPool(poolId);

        emit Allocated(acceptedRecipientId, recipient.proposalBid, pool.token, _sender);
    }

    /// @notice Distribute the upcoming milestone to acceptedRecipientId.
    /// @dev '_sender' must be a pool manager to distribute.
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory, bytes memory, address _sender)
        internal
        virtual
        override
        onlyInactivePool
        onlyPoolManager(_sender)
    {
        // check to make sure there is a pending milestone
        if (upcomingMilestone >= milestones.length) {
            revert INVALID_MILESTONE();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        Milestone storage milestone = milestones[upcomingMilestone];
        Recipient memory recipient = _recipients[acceptedRecipientId];

        if (recipient.proposalBid > poolAmount) {
            revert NOT_ENOUGH_FUNDS();
        }

        // Calculate the amount to be distributed for the milestone
        uint256 amount = (recipient.proposalBid * milestone.amountPercentage) / 1e18;

        // Get the pool, subtract the amount and transfer to the recipient
        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        // Set the milestone status to 'Accepted'
        milestone.milestoneStatus = RecipientStatus.Accepted;

        // Increment the upcoming milestone
        upcomingMilestone++;

        // Emit events for the milestone and the distribution
        emit MilestoneStatusChanged(upcomingMilestone, RecipientStatus.Accepted);
        emit Distributed(acceptedRecipientId, recipient.recipientAddress, amount, _sender);
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

        if (acceptedRecipientId != address(0) && acceptedRecipientId != _recipientId) {
            recipient.recipientStatus =
                recipient.recipientStatus > RecipientStatus.None ? RecipientStatus.Rejected : RecipientStatus.None;
        }
    }

    /// @notice Increase max bid for RFP pool
    /// @param _maxBid The new max bid to be set
    /// @dev Emits a 'MilestoneRejected()' event.
    function _increaseMaxBid(uint256 _maxBid) internal {
        if (_maxBid < maxBid) {
            revert AMOUNT_TOO_LOW();
        }
        maxBid = _maxBid;

        emit MaxBidIncreased(maxBid);
    }

    /// @notice Get the payout summary for the accepted recipient.
    /// @return Returns the payout summary for the accepted recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _recipients[_recipientId];
        return PayoutSummary(recipient.recipientAddress, recipient.proposalBid);
    }

    /// @notice Checks if address is eligible allocator.
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
