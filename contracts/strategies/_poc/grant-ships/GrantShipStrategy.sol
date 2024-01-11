// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
// Intefaces
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {ShipInitData} from "./libraries/GrantShipShared.sol";
import {GameManagerStrategy} from "./GameManagerStrategy.sol";

/// @title Grant Ships Strategy.
/// @author @jord<https://github.com/jordanlesich>, @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Sub-Strategy used to allocate & distribute funds to recipients with milestone payouts. TThis contract is modified version of the Direct Grants Strategy.
/// This contract is deployed by a MetaStrategy contract that creates a shared set of rules for multiple implmentations of this contract.

/// Just like the Direct Grants Strategy, this strategy is designed for recipients or grant managers to submit milestones for review and approval.
/// a few notable differences are:

/// Permissions: (Write permission changes here)

/// Game Rules: (Explain how GameManager contract impacts this sub-strategy)

/// Hats Protocol: (Explain how the hats protocol impacts this sub-strategy)

/// GameFacilitators: (Explain that the game facilitators, not pool managers are in control of allocations)

/// ShipOperators: (Explain how the ship operators are in control of reviewwing milestones and reviewing funds))

/// Flagging: (Facilitators can flag this ship and pause allocation/distribution)

/// Posting: Each player in this game can post arbitrary data (mostly updates) to the game contract.
/// This data is stored as event data to be indexed and viewed by the public.

contract GrantShipStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Structs =============
    /// ================================

    enum RoleType {
        None,
        Recipient,
        GameFacilitator,
        ShipOperator
    }

    enum FlagType {
        None,
        Yellow,
        Red
    }

    struct Flag {
        FlagType flagType;
        Metadata flagReason;
        bool isResolved;
        Metadata resolutionReason;
    }

    /// @notice Struct to hold details about the milestone
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        Status milestoneStatus;
    }

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        Status recipientStatus;
        Status milestonesReviewStatus;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when there is collision with the Flag nonce
    error FLAG_ALREADY_EXISTS();

    /// @notice Throws when there is collision with the Flag nonce
    error INVALID_FLAG();

    /// @notice Throws when the ship still has unresolved red flags
    error UNRESOLVED_RED_FLAGS();

    /// @notice Throws when the milestone is invalid.
    error INVALID_MILESTONE();

    /// @notice Throws when the milestone is already accepted.
    error MILESTONE_ALREADY_ACCEPTED();

    /// @notice Throws when the milestones are already set.
    error MILESTONES_ALREADY_SET();

    /// @notice Throws when the allocation exceeds the pool amount.
    error ALLOCATION_EXCEEDS_POOL_AMOUNT();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted for the registration of a recipient and the status is updated.
    event RecipientStatusChanged(address recipientId, Status status);

    /// @notice Emitted for the submission of a milestone.
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);

    /// @notice Emitted for the status change of a milestone.
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, Status status);

    /// @notice Emitted for the milestones set.
    event MilestonesSet(address recipientId, uint256 milestonesLength);

    event FlagIssued(uint256 nonce, FlagType flagType, Metadata flagReason);

    event FlagResolved(uint256 nonce, Metadata resolutionReason);

    event MilestonesReviewed(address recipientId, Status status);

    event PoolWithdraw(uint256 amount);

    event UpdatePosted(string indexed tag, RoleType indexed role, address indexed recipientId, Metadata content);

    /// ================================
    /// ===== Game (Global) State ======
    /// ================================

    /// @notice Reference to the 'GameManager' contract interface.
    GameManagerStrategy internal _gameManager;

    /// @notice Reference to GameManager's 'Hats' contract interface.
    IHats internal _hats;

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Flag to check if registry gating is enabled.
    bool public registryGating;

    /// @notice Flag to check if metadata is required.
    bool public metadataRequired;

    /// @notice Flag to check if grant amount is required.
    bool public grantAmountRequired;

    /// @notice The 'Registry' contract interface.
    IRegistry private _registry;

    /// @notice The total amount allocated to grant/recipient.
    uint256 public allocatedGrantAmount;

    /// @notice The total amount allocated to grant/recipient.
    uint256 public operatorHatId;

    ///@notice
    uint256 public unresolvedRedFlags;

    /// @notice Flag to check if the Ship has been flagged for a violation
    mapping(uint256 nonce => Flag) public violationFlags;

    /// @notice Internal collection of accepted recipients able to submit milestones
    address[] private _acceptedRecipientIds;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) private _recipients;

    /// @notice This maps accepted recipients to their milestones
    /// @dev 'recipientId' to 'Milestone'
    mapping(address => Milestone[]) public milestones;

    /// @notice This maps accepted recipients to their upcoming milestone
    /// @dev 'recipientId' to 'nextMilestone'
    mapping(address => uint256) public upcomingMilestone;

    /// ===============================
    /// ======== Modifiers ============
    /// ===============================

    modifier onlyGameFacilitator(address _sender) {
        if (!isGameFacilitator(_sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    modifier onlyShipOperator(address _sender) {
        if (!isShipOperator(_sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    modifier noUnresolvedRedFlags() {
        if (hasUnresolvedRedFlags()) {
            revert UNRESOLVED_RED_FLAGS();
        }
        _;
    }

    modifier onlyGameManger(address _sender) {
        if (_sender != address(_gameManager)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the GrantShips Simple Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool registryGating, bool metadataRequired, bool grantAmountRequired)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (ShipInitData memory shipInitData, address payable _gameManagerAddress) =
            abi.decode(_data, (ShipInitData, address));
        __GrantShipStrategy_init(_poolId, shipInitData, _gameManagerAddress);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _poolId ID of the pool - required to initialize the BaseStrategy
    /// @param _initData The init params for the strategy (bool registryGating, bool metadataRequired, bool grantAmountRequired)
    function __GrantShipStrategy_init(
        uint256 _poolId,
        ShipInitData memory _initData,
        address payable _gameManagerAddress
    ) internal {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        GameManagerStrategy gameManager = GameManagerStrategy(_gameManagerAddress);
        _gameManager = gameManager;

        _hats = IHats(address(_gameManager.getHatsAddress()));

        // Set the strategy specific variables
        registryGating = _initData.registryGating;
        metadataRequired = _initData.metadataRequired;
        grantAmountRequired = _initData.grantAmountRequired;
        operatorHatId = _initData.operatorHatId;
        _registry = allo.getRegistry();

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

    function getFlag(uint256 _nonce) external view returns (Flag memory) {
        return violationFlags[_nonce];
    }

    /// @notice Get recipient status
    /// @dev The global 'Status' is used at the protocol level and most strategies will use this.
    /// @param _recipientId ID of the recipient
    /// @return Status Returns the global recipient status
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    function isGameFacilitator(address _gameFacilitator) public view returns (bool) {
        return _hats.isWearerOfHat(_gameFacilitator, _gameManager.gameFacilitatorHatId());
    }

    function isShipOperator(address _shipOperator) public view returns (bool) {
        return _hats.isWearerOfHat(_shipOperator, operatorHatId);
    }

    //Todo: update comment
    /// @notice Checks if address is eligible allocator.
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return isGameFacilitator(_allocator);
    }

    /// @notice Get the status of the milestone of an recipient.
    /// @dev This is used to check the status of the milestone of an recipient and is strategy specific
    /// @param _recipientId ID of the recipient
    /// @param _milestoneId ID of the milestone
    /// @return Status Returns the status of the milestone using the 'Status' enum
    function getMilestoneStatus(address _recipientId, uint256 _milestoneId) external view returns (Status) {
        return milestones[_recipientId][_milestoneId].milestoneStatus;
    }

    /// @notice Get the milestones.
    /// @param _recipientId ID of the recipient
    /// @return Milestone[] Returns the milestones for a 'recipientId'
    function getMilestones(address _recipientId) external view returns (Milestone[] memory) {
        return milestones[_recipientId];
    }

    function hasUnresolvedRedFlags() public view returns (bool) {
        return unresolvedRedFlags > 0;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    function postUpdate(string memory _tag, Metadata memory _content, address _recipientId) external {
        bool isNotRecipient = _recipientId == address(0);

        if (isGameFacilitator(msg.sender) && isNotRecipient) {
            emit UpdatePosted(_tag, RoleType.GameFacilitator, _recipientId, _content);
        } else if (isShipOperator(msg.sender) && isNotRecipient) {
            emit UpdatePosted(_tag, RoleType.ShipOperator, _recipientId, _content);
        } else if (_isProfileMember(_recipientId, msg.sender) && !isNotRecipient) {
            emit UpdatePosted(_tag, RoleType.Recipient, _recipientId, _content);
        } else {
            revert UNAUTHORIZED();
        }
    }

    /// Todo: update comment
    /// @notice Set milestones for recipient.
    /// @dev 'msg.sender' must be recipient creator or pool manager. Emits a 'MilestonesReviewed()' event.
    /// @param _recipientId ID of the recipient
    /// @param _milestones The milestones to be set
    function setMilestones(address _recipientId, Milestone[] memory _milestones) external {
        // Todo: Do a deep dive on _recipientId. If this is anchor address, and the sender is not a member of the profile,
        // then the person who created the profile and recipient is going to have to use Anchor.execute to call this
        // which is infeasible for quickly building a frontend.

        bool isRecipientCreator = (msg.sender == _recipientId) || _isProfileMember(_recipientId, msg.sender);
        bool isOperator = isShipOperator(msg.sender);
        if (!isRecipientCreator && !isOperator) {
            revert UNAUTHORIZED();
        }

        Recipient storage recipient = _recipients[_recipientId];

        // Check if the recipient is accepted, otherwise revert
        if (recipient.recipientStatus != Status.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        if (recipient.milestonesReviewStatus == Status.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }

        _setMilestones(_recipientId, _milestones);

        if (isOperator) {
            recipient.milestonesReviewStatus = Status.Accepted;
            emit MilestonesReviewed(_recipientId, Status.Accepted);
        }
    }

    /// @notice Set milestones of the recipient
    /// @dev Emits a 'MilestonesReviewed()' event
    /// @param _recipientId ID of the recipient
    /// @param _status The status of the milestone review
    function reviewSetMilestones(address _recipientId, Status _status) external onlyShipOperator(msg.sender) {
        Recipient storage recipient = _recipients[_recipientId];

        // Check if the recipient has any milestones, otherwise revert
        if (milestones[_recipientId].length == 0) {
            revert INVALID_MILESTONE();
        }

        // Check if the recipient is 'Accepted', otherwise revert
        if (recipient.milestonesReviewStatus == Status.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }

        // Check if the status is 'Accepted' or 'Rejected', otherwise revert
        if (_status == Status.Accepted || _status == Status.Rejected) {
            // Set the status of the milestone review
            recipient.milestonesReviewStatus = _status;

            // Emit event for the milestone review
            emit MilestonesReviewed(_recipientId, _status);
        }
    }

    /// @notice Submit milestone by the recipient.
    /// @dev 'msg.sender' must be the 'recipientId' (this depends on whether your using registry gating) and must be a member
    ///      of a 'Profile' to submit a milestone and '_recipientId'.
    ///      must NOT be the same as 'msg.sender'. Emits a 'MilestonesSubmitted()' event.
    /// @param _recipientId ID of the recipient
    /// @param _metadata The proof of work
    function submitMilestone(address _recipientId, uint256 _milestoneId, Metadata calldata _metadata) external {
        // Check if the '_recipientId' is the same as 'msg.sender' and if it is NOT, revert. This
        // also checks if the '_recipientId' is a member of the 'Profile' and if it is NOT, revert.
        if (_recipientId != msg.sender && !_isProfileMember(_recipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        Recipient memory recipient = _recipients[_recipientId];

        // Check if the recipient is 'Accepted', otherwise revert
        if (recipient.recipientStatus != Status.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        Milestone[] storage recipientMilestones = milestones[_recipientId];

        // Check if the milestone is the upcoming one
        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        // Todo: Check we that this works in all cases.
        // Seems like we should check for the statuses that we want instead of ruling out Accepted

        // Check if the milestone is accepted, otherwise revert
        if (milestone.milestoneStatus == Status.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        // Set the milestone metadata and status
        milestone.metadata = _metadata;
        milestone.milestoneStatus = Status.Pending;

        // Emit event for the milestone submission
        emit MilestoneSubmitted(_recipientId, _milestoneId, _metadata);
    }

    /// @notice Reject pending milestone of the recipient.
    /// @dev 'msg.sender' must be a pool manager to reject a milestone. Emits a 'MilestonesStatusChanged()' event.
    /// @param _recipientId ID of the recipient
    /// @param _milestoneId ID of the milestone
    function rejectMilestone(address _recipientId, uint256 _milestoneId) external onlyShipOperator(msg.sender) {
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        // Check if the milestone is the upcoming one
        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        // Check if the milestone is NOT 'Accepted' already, and revert if it is
        if (milestone.milestoneStatus == Status.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        // Set the milestone status to 'Rejected'
        milestone.milestoneStatus = Status.Rejected;

        // Emit event for the milestone rejection
        emit MilestoneStatusChanged(_recipientId, _milestoneId, Status.Rejected);
    }
    // Todo test if I can just send flagType(8) and see what happens

    function issueFlag(uint256 _nonce, FlagType _flagType, Metadata calldata _flagReason)
        external
        onlyGameFacilitator(msg.sender)
    {
        Flag storage flag = violationFlags[_nonce];

        // check for potential nonce collisions or overwrites
        if (flag.flagType != FlagType.None) {
            revert FLAG_ALREADY_EXISTS();
        }
        // check for correct flag type
        if (_flagType != FlagType.Red && _flagType != FlagType.Yellow) {
            revert INVALID_FLAG();
        }

        flag.flagType = _flagType;
        flag.flagReason = _flagReason;

        if (_flagType == FlagType.Red) {
            unresolvedRedFlags++;
        }

        emit FlagIssued(_nonce, _flagType, _flagReason);
    }

    function resolveFlag(uint256 _nonce, Metadata calldata _resolutionReason)
        external
        onlyGameFacilitator(msg.sender)
    {
        Flag storage flag = violationFlags[_nonce];

        if (flag.flagType == FlagType.None) {
            revert INVALID_FLAG();
        }

        if (flag.isResolved) {
            revert INVALID_FLAG();
        }

        flag.isResolved = true;
        flag.resolutionReason = _resolutionReason;

        if (flag.flagType == FlagType.Red) {
            unresolvedRedFlags--;
        }

        emit FlagResolved(_nonce, _resolutionReason);
    }

    /// Todo: Make sure that the recipient is not 'stuck' at Status.InReview in all possible cases
    /// Also make sure the UX of getting back in the flow is easy to implement and clear to the user

    /// @notice Set the status of the recipient to 'InReview'
    /// @dev Emits a 'RecipientStatusChanged()' event
    /// @param _recipientIds IDs of the recipients
    function setRecipientStatusToInReview(address[] calldata _recipientIds) external {
        if (!isShipOperator(msg.sender) && !isGameFacilitator(msg.sender)) {
            revert UNAUTHORIZED();
        }

        uint256 recipientLength = _recipientIds.length;
        for (uint256 i; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            _recipients[recipientId].recipientStatus = Status.InReview;

            emit RecipientStatusChanged(recipientId, Status.InReview);

            unchecked {
                i++;
            }
        }
    }

    function managerIncreasePoolAmount(uint256 _amount) external onlyGameManger(msg.sender) {
        poolAmount += _amount;
    }

    /// @notice Toggle the status between active and inactive.
    /// @dev 'msg.sender' must be a pool manager to close the pool. Emits a 'PoolActive()' event.
    /// @param _flag The flag to set the pool to active or inactive
    function setPoolActive(bool _flag) external onlyGameFacilitator(msg.sender) {
        _setPoolActive(_flag);
        emit PoolActive(_flag);
    }

    /// @notice Withdraw funds from pool.
    /// @dev 'msg.sender' must be a pool manager to withdraw funds.
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyGameFacilitator(msg.sender) onlyInactivePool {
        // Decrement the pool amount\

        if (_amount > poolAmount) {
            revert NOT_ENOUGH_FUNDS();
        }

        poolAmount -= _amount;

        // Transfer the amount to the pool manager
        _transferAmount(allo.getPool(poolId).token, address(_gameManager), _amount);

        // Emit event for the withdrawal

        emit PoolWithdraw(_amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Register a recipient to the pool.
    /// @dev Emits a 'Registered()' event
    /// @param _data The data to be decoded
    /// @custom:data when 'registryGating' is 'true' -> (address recipientId, address recipientAddress, uint256 grantAmount, Metadata metadata)
    ///              when 'registryGating' is 'false' -> (address recipientAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The id of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        noUnresolvedRedFlags
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        uint256 grantAmount;
        Metadata memory metadata;

        // Decode '_data' depending on the 'registryGating' flag
        /// @custom:data when 'true' -> (address recipientId, address recipientAddress, uint256 grantAmount, Metadata metadata)
        if (registryGating) {
            (recipientId, recipientAddress, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            /// @custom:data when 'false' -> (address recipientAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
            (recipientAddress, registryAnchor, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            // Check if the registry anchor is valid so we know whether to use it or not
            isUsingRegistryAnchor = registryAnchor != address(0);

            // Ternerary to set the recipient id based on whether or not we are using the 'registryAnchor' or '_sender'
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        // Check if the grant amount is required and if it is, check if it is greater than 0, otherwise revert
        if (grantAmountRequired && grantAmount == 0) {
            revert INVALID_REGISTRATION();
        }

        // Check if the recipient is not already accepted, otherwise revert
        if (_recipients[recipientId].recipientStatus == Status.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        // Check if the metadata is required and if it is, check if it is valid, otherwise revert
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // Create the recipient instance
        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            useRegistryAnchor: registryGating ? true : isUsingRegistryAnchor,
            grantAmount: grantAmount,
            metadata: metadata,
            recipientStatus: Status.Pending,
            milestonesReviewStatus: Status.Pending
        });

        // Add the recipient to the accepted recipient ids mapping
        _recipients[recipientId] = recipient;

        // Emit event for the registration
        emit Registered(recipientId, _data, _sender);
    }

    /// Todo: Document changes: Facilitators can allocate funds to recipients, not pool managers
    /// @notice Allocate amount to recipent for GrantShips.
    /// @dev '_sender' must be a pool manager to allocate. Emits 'RecipientStatusChanged() and 'Allocated()' events.
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, Status recipientStatus, uint256 grantAmount)
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        noUnresolvedRedFlags
        onlyGameFacilitator(_sender)
    {
        // Decode the '_data'
        (address recipientId, Status recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, Status, uint256));

        Recipient storage recipient = _recipients[recipientId];

        // Todo: figure out why we need this check
        // Most grant managers would like to see a project's milestones before allocating funds
        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        if (recipient.recipientStatus != Status.Accepted && recipientStatus == Status.Accepted) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            allocatedGrantAmount += grantAmount;

            // Todo: Maybe we should do this same check on register recipient?
            // Not doing so might create issues where a there isn't enough funds to allocate to a recipient

            // Check if the allocated grant amount exceeds the pool amount and reverts if it does
            if (allocatedGrantAmount > poolAmount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }
            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = Status.Accepted;

            // Emit event for the acceptance
            emit RecipientStatusChanged(recipientId, Status.Accepted);

            // Emit event for the allocation
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (recipient.recipientStatus != Status.Rejected && recipientStatus == Status.Rejected) {
            recipient.recipientStatus = Status.Rejected;

            // Emit event for the rejection
            emit RecipientStatusChanged(recipientId, Status.Rejected);
        }
    }

    /// @notice Distribute the upcoming milestone to recipients.
    /// @dev '_sender' must be a pool manager to distribute.
    /// @param _recipientIds The recipient ids of the distribution
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        noUnresolvedRedFlags
        nonReentrant
        onlyShipOperator(_sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i; i < recipientLength;) {
            _distributeUpcomingMilestone(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Distribute the upcoming milestone.
    /// @dev Emits 'MilestoneStatusChanged() and 'Distributed()' events.
    /// @param _recipientId The recipient of the distribution
    /// @param _sender The sender of the distribution
    function _distributeUpcomingMilestone(address _recipientId, address _sender) private {
        uint256 milestoneToBeDistributed = upcomingMilestone[_recipientId];
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        Recipient memory recipient = _recipients[_recipientId];
        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        // check if milestone is not rejected or already paid out

        if (milestoneToBeDistributed > recipientMilestones.length || milestone.milestoneStatus != Status.Pending) {
            revert INVALID_MILESTONE();
        }

        // Calculate the amount to be distributed for the milestone
        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        // Get the pool, subtract the amount and transfer to the recipient
        IAllo.Pool memory pool = allo.getPool(poolId);

        poolAmount -= amount;

        // Set the milestone status to 'Accepted'
        milestone.milestoneStatus = Status.Accepted;

        _transferAmount(pool.token, recipient.recipientAddress, amount);

        // Increment the upcoming milestone
        upcomingMilestone[_recipientId]++;

        // Emit events for the milestone and the distribution
        emit MilestoneStatusChanged(_recipientId, milestoneToBeDistributed, Status.Accepted);
        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
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
    }

    /// @notice Get the payout summary for the accepted recipient.
    /// @return Returns the payout summary for the accepted recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _getRecipient(_recipientId);
        return PayoutSummary(recipient.recipientAddress, recipient.grantAmount);
    }

    /// @notice Set the milestones for the recipient.
    /// @param _recipientId ID of the recipient
    /// @param _milestones The milestones to be set
    function _setMilestones(address _recipientId, Milestone[] memory _milestones) internal {
        uint256 totalAmountPercentage;

        // Clear out the milestones and reset the index to 0
        if (milestones[_recipientId].length > 0) {
            delete milestones[_recipientId];
        }

        uint256 milestonesLength = _milestones.length;

        // Loop through the milestones and set them
        for (uint256 i; i < milestonesLength;) {
            Milestone memory milestone = _milestones[i];

            // Reverts if the milestone status is 'None'
            if (milestone.milestoneStatus != Status.None) {
                revert INVALID_MILESTONE();
            }

            // TODO: I see we check on line 649, but it seems we need to check when added it is NOT greater than 100%?
            // Add the milestone percentage amount to the total percentage amount
            totalAmountPercentage += milestone.amountPercentage;

            // Add the milestone to the recipient's milestones
            milestones[_recipientId].push(milestone);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONE();
        }

        emit MilestonesSet(_recipientId, milestonesLength);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
