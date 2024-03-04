// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// import "forge-std/Test.sol";

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
contract GrantShipStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct/Enum =========
    /// ================================

    /// @notice Enum for deternining flag type
    enum FlagType {
        None,
        Yellow,
        Red
    }

    /// @notice Stores details about a flag, its issuance, and resolution
    struct Flag {
        FlagType flagType;
        bool isResolved;
    }

    /// @notice Struct to hold details about the milestone
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        Status milestoneStatus;
    }

    /// @notice Struct to hold details of a recipient
    struct Recipient {
        bool useRegistryAnchor;
        address receivingAddress;
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

    /// @notice Throws when there is an incorrect FlagType
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

    /// @notice Emitted when the strategy is initialized
    event GrantShipInitialized(
        uint256 poolId,
        bool registryGating,
        bool metadataRequired,
        bool grantAmountRequired,
        uint256 operatorHatId,
        uint256 facilitatorHatId,
        address registryAnchor
    );

    /// @notice Emitted for the registration of a recipient and the status is updated.
    event RecipientStatusChanged(address recipientId, Status status, Metadata reason);

    /// @notice Emitted when a milestone is created
    event MilestoneCreated(address recipientId, uint256 milestoneId, uint256 amountPercentage, Metadata metadata);

    /// @notice Emitted for the submission of a milestone.
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);

    /// @notice Emitted for the status change of a milestone.
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, Status status);

    /// @notice Emitted for the rejection of a single milestone.
    event MilestoneRejected(address recipientId, uint256 milestoneId, Metadata reason);

    /// @notice Emitted for the milestones set.
    event MilestonesSet(address recipientId, uint256 milestonesLength);

    ///@notice Emitted when a flag is issued to this GrantShip
    event FlagIssued(uint256 nonce, FlagType flagType, Metadata flagReason);

    ///@notice Emitted when a flag is resolved
    event FlagResolved(uint256 nonce, Metadata resolutionReason);

    /// @notice Emitted for the review of the milestones. Contains a 'reason'
    event MilestonesReviewed(address recipientId, Status status, Metadata reason);

    /// @notice Emitted when funds for this pool have been withdrawn.
    event PoolWithdraw(uint256 amount);

    /// @notice Emitted when funds have been added to this pool.
    event PoolFunded(uint256 poolId, uint256 amount, uint256 amountPercentage);

    /// @notice Emitted when a game player creates a metadata update
    event UpdatePosted(string tag, uint256 role, address recipientId, Metadata content);

    /// @notice Emitted when a grant is completed
    event GrantComplete(address recipientId, uint256 amount);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Reference to the 'GameManager' contract interface.
    GameManagerStrategy internal _gameManager;

    /// @notice Reference to GameManager's 'Hats' contract interface.
    IHats internal _hats;

    /// @notice Flag to check if registry gating is enabled.
    bool public registryGating;

    /// @notice Flag to check if metadata is required.
    bool public metadataRequired;

    /// @notice Flag to check if grant amount is required.
    bool public grantAmountRequired;

    /// @notice The registryId of this GrantShip in the parent GameManagerStrategy
    address public shipRegistryAnchor;

    /// @notice The 'Registry' contract interface.
    IRegistry private _registry;

    /// @notice The total amount allocated to recipients.
    uint256 public allocatedGrantAmount;

    /// @notice The Hats Protocol ID for Ship Operator.
    uint256 public operatorHatId;

    /// @notice The Hats Protocol ID for the Game Gacilitator.
    uint256 public facilitatorHatId;

    ///@notice The total amount of unresolved red flags
    uint256 public unresolvedRedFlags;

    /// @notice Flag to check if the Ship has been flagged for a violation
    mapping(uint256 nonce => Flag) public violationFlags;

    /// @notice Internal collection of accepted recipients able to submit milestones
    address[] private _acceptedRecipientIds;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) private _recipients;

    /// @notice This maps recipients to their milestones
    /// @dev 'recipientId' to 'Milestone'
    mapping(address => Milestone[]) public milestones;

    /// @notice This maps recipients to their upcoming milestone
    /// @dev 'recipientId' to 'nextMilestone'
    mapping(address => uint256) public upcomingMilestone;

    /// ===============================
    /// ======== Modifiers ============
    /// ===============================

    /// @notice odifier to check if sender is a game facilitator
    /// @dev Throws if the sender does not hold a Game Facilitator hat
    modifier onlyGameFacilitator(address _sender) {
        if (!isGameFacilitator(_sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if sender is a ship operator
    /// @dev Throws if the sender does not hold a Ship Operator hat
    modifier onlyShipOperator(address _sender) {
        if (!isShipOperator(_sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if this GrantShip Strategy does not have any unresolved red flags
    /// @dev Throws if the GrantShip Strategy has unresolved red flags
    modifier noUnresolvedRedFlags() {
        if (hasUnresolvedRedFlags()) {
            revert UNRESOLVED_RED_FLAGS();
        }
        _;
    }

    /// @notice Modifier to check if the current game round is active.
    /// @dev Checks to see if the GameManager is finished its current round.
    /// Uses the inverse of the GameManager's isPoolActive()
    modifier onlyGameActive() {
        if (_gameManager.isPoolActive()) {
            revert UNRESOLVED_RED_FLAGS();
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
    /// @custom:data (ShipInitData (see GrantShipsShared.sol), address payable _gameManagerAddress)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (ShipInitData memory shipInitData, address payable _gameManagerAddress) =
            abi.decode(_data, (ShipInitData, address));
        __GrantShipStrategy_init(_poolId, shipInitData, _gameManagerAddress);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy, and sets this strategies init params
    /// @param _poolId ID of the pool - required to initialize the BaseStrategy
    /// @param _initData The init params for the strategy (ShipInitData, address payable _gameManagerAddress)
    function __GrantShipStrategy_init(
        uint256 _poolId,
        ShipInitData memory _initData,
        address payable _gameManagerAddress
    ) internal {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        _gameManager = GameManagerStrategy(_gameManagerAddress);

        _hats = IHats(address(_gameManager.getHatsAddress()));

        // Set the strategy specific variables
        registryGating = _initData.registryGating;
        metadataRequired = _initData.metadataRequired;
        grantAmountRequired = _initData.grantAmountRequired;
        operatorHatId = _initData.operatorHatId;
        facilitatorHatId = _initData.facilitatorHatId;
        shipRegistryAnchor = _initData.recipientId;
        _registry = allo.getRegistry();

        // Set the pool to active - this is required for the strategy to work and distribute funds
        // NOTE: There may be some cases where you may want to not set this here, but will be strategy specific
        _setPoolActive(true);

        emit GrantShipInitialized(
            _poolId,
            registryGating,
            metadataRequired,
            grantAmountRequired,
            operatorHatId,
            facilitatorHatId,
            shipRegistryAnchor
        );
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return Recipient Returns the Recipient struct
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get the Flag
    /// @param _nonce ID of the flag
    /// @return Flag Returns the Flag struct
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

    /// @notice Tests if address holds a Game Facilitator hat
    /// @param _gameFacilitator Address of the game facilitator
    /// @return 'true' if the address holds a Game Facilitator hat, otherwise 'false'
    function isGameFacilitator(address _gameFacilitator) public view returns (bool) {
        return _hats.isWearerOfHat(_gameFacilitator, facilitatorHatId);
    }

    /// @notice Tests if address holds a Ship Operator hat
    /// @param _shipOperator Address of the ship operator
    /// @return 'true' if the address holds a Ship Operator hat, otherwise 'false'
    function isShipOperator(address _shipOperator) public view returns (bool) {
        return _hats.isWearerOfHat(_shipOperator, operatorHatId);
    }

    /// @notice Tests if address is eligible allocator.
    /// @dev This is used to check if the allocator is a GameFacilitator and holds the facilitator hat.
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a game facilitator, otherwise false
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

    /// @notice Get the upcoming milestone.
    /// @param _recipientId ID of the recipient
    /// @return uint256 Returns the upcoming milestone for a 'recipientId'
    function getUpcomingMilestone(address _recipientId) external view returns (uint256) {
        return upcomingMilestone[_recipientId];
    }

    /// @notice Checks if this Ship has any unresolved red flags
    /// @return 'true' if the Ship has unresolved red flags, otherwise 'false'
    function hasUnresolvedRedFlags() public view returns (bool) {
        return unresolvedRedFlags > 0;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Post an update to the this Ship's feed
    /// @dev 'msg.sender' must be a game facilitator, ship operator, or a recipient to post an update
    /// @param _tag The tag of the update. Used to index by topic,
    /// @param _content The content of the update
    /// @param _recipientId The recipient to post the update. Expecting address(0) if poster has is Game Facilitator or Ship Operator
    function postUpdate(string memory _tag, Metadata memory _content, address _recipientId) external {
        bool isNotRecipient = _recipientId == address(0);

        if (isGameFacilitator(msg.sender) && isNotRecipient) {
            emit UpdatePosted(_tag, _gameManager.gameFacilitatorHatId(), _recipientId, _content);
        } else if (isShipOperator(msg.sender) && isNotRecipient) {
            emit UpdatePosted(_tag, operatorHatId, _recipientId, _content);
        } else if (_isProfileMember(_recipientId, msg.sender) && !isNotRecipient) {
            emit UpdatePosted(_tag, 0, _recipientId, _content);
        } else {
            revert UNAUTHORIZED();
        }
    }

    /// @notice Set milestones for recipient.
    /// @dev 'msg.sender' must be recipient creator or ShipOperator. Emits a 'MilestonesReviewed()' event.
    /// @param _recipientId ID of the recipient
    /// @param _milestones The milestones to be set
    /// @param _reason The reason for setting the milestones, only used if Milestone is approved by a shipOperator.
    function setMilestones(address _recipientId, Milestone[] memory _milestones, Metadata calldata _reason) external {
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
            emit MilestonesReviewed(_recipientId, Status.Accepted, _reason);
        }
    }

    /// @notice Set milestones of the recipient
    /// @dev Emits a 'MilestonesReviewed()' event
    /// @param _recipientId ID of the recipient
    /// @param _status The status of the milestone review
    /// @param _reason The reason for setting the milestones
    function reviewSetMilestones(address _recipientId, Status _status, Metadata calldata _reason)
        external
        onlyShipOperator(msg.sender)
    {
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
            emit MilestonesReviewed(_recipientId, _status, _reason);
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

        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];
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
    /// @param _reason The reason for rejecting the milestone
    function rejectMilestone(address _recipientId, uint256 _milestoneId, Metadata calldata _reason)
        external
        onlyShipOperator(msg.sender)
    {
        Milestone[] storage recipientMilestones = milestones[_recipientId];

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
        emit MilestoneRejected(_recipientId, _milestoneId, _reason);
    }

    /// @notice Issue a flag to this GrantShip
    /// @dev 'msg.sender' must be a game facilitator to issue a flag
    /// @param _nonce The nonce of the flag
    /// @param _flagType The type of flag to issue (Red or Yellow)
    /// @param _reason The reason for issuing the flag
    function issueFlag(uint256 _nonce, FlagType _flagType, Metadata calldata _reason)
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

        if (_flagType == FlagType.Red) {
            unresolvedRedFlags++;
        }

        emit FlagIssued(_nonce, _flagType, _reason);
    }

    /// @notice Resolve a flag issued to this GrantShip
    /// @dev 'msg.sender' must be a game facilitator to resolve a flag
    /// @param _nonce The nonce of the flag
    /// @param _reason The reason for resolving the flag
    function resolveFlag(uint256 _nonce, Metadata calldata _reason) external onlyGameFacilitator(msg.sender) {
        Flag storage flag = violationFlags[_nonce];

        if (flag.flagType == FlagType.None) {
            revert INVALID_FLAG();
        }

        if (flag.isResolved) {
            revert INVALID_FLAG();
        }

        flag.isResolved = true;

        if (flag.flagType == FlagType.Red) {
            unresolvedRedFlags--;
        }

        emit FlagResolved(_nonce, _reason);
    }

    /// Review: Make sure that the recipient is not 'stuck' at Status.InReview in all possible cases
    /// OR: Make sure that the recipient isn't able to 'jump ahead'.
    /// Also make sure the UX of getting back in the flow is easy to implement and clear to the user

    /// @notice Set the status of the recipient to 'InReview'
    /// @dev Emits a 'RecipientStatusChanged()' event
    /// @param _recipientIds IDs of the recipients
    /// @param _reasons The reasons for setting statuses to 'InReview'
    function setRecipientStatusToInReview(address[] calldata _recipientIds, Metadata[] calldata _reasons) external {
        if (!isShipOperator(msg.sender) && !isGameFacilitator(msg.sender)) {
            revert UNAUTHORIZED();
        }
        if (_recipientIds.length != _reasons.length) {
            revert ARRAY_MISMATCH();
        }

        uint256 recipientLength = _recipientIds.length;
        for (uint256 i; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            _recipients[recipientId].recipientStatus = Status.InReview;

            emit RecipientStatusChanged(recipientId, Status.InReview, _reasons[i]);

            unchecked {
                i++;
            }
        }
    }

    /// Review: This is currently the only way for a parent strategy to properly distribute to a child strategy
    /// Or at least the only solution that I've been able to discover. Any other ideas are welcome.

    /// @notice Increase the pool amount for this pool.
    /// @dev 'msg.sender' must be the parent GameManagerStrategy to increase the pool amount.
    function managerIncreasePoolAmount(uint256 _amount) external {
        if (msg.sender != address(_gameManager)) revert UNAUTHORIZED();

        poolAmount += _amount;
        emit PoolFunded(poolId, _amount, 0);
    }

    /// @notice Toggle the status between active and inactive.
    /// @dev 'msg.sender' must be the GameFacilitator to close the pool. Emits a 'PoolActive()' event.
    /// @param _flag The flag to set the pool to active or inactive
    function setPoolActive(bool _flag) external onlyGameFacilitator(msg.sender) {
        _setPoolActive(_flag);
        emit PoolActive(_flag);
    }

    /// @notice Withdraw funds from pool.
    /// @dev 'msg.sender' must be a pool manager to withdraw funds.
    /// @dev Only sends funds to the game manager.
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyGameFacilitator(msg.sender) onlyInactivePool nonReentrant {
        // CHECK
        if (_amount > poolAmount) {
            revert NOT_ENOUGH_FUNDS();
        }

        // EFFECT
        poolAmount -= _amount;

        // Review: Using fund pool and approve to ensure that
        // game manager's pool amount is correct when it recieves funds
        // There's probably a better pattern for this.

        // INTERACTION

        // get pool token address
        IERC20 token = IERC20(allo.getPool(poolId).token);
        // approve Allo to transfer funds
        token.approve(address(allo), _amount);
        // Transfer the amount to the pool manager
        allo.fundPool(_gameManager.getPoolId(), _amount);

        // Emit event for the withdrawal
        emit PoolWithdraw(_amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Register a recipient to the pool.
    /// @dev Emits a 'Registered()' event
    /// @param _data The data to be decoded
    /// @custom:data when 'registryGating' is 'true' -> (address recipientId, address receivingAddress, uint256 grantAmount, Metadata metadata)
    ///              when 'registryGating' is 'false' -> (address receivingAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The id of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyGameActive
        noUnresolvedRedFlags
        returns (address recipientId)
    {
        address receivingAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        uint256 grantAmount;
        Metadata memory metadata;

        // Decode '_data' depending on the 'registryGating' flag
        /// @custom:data when 'true' -> (address recipientId, address receivingAddress, uint256 grantAmount, Metadata metadata)
        if (registryGating) {
            (recipientId, receivingAddress, grantAmount, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            /// @custom:data when 'false' -> (address receivingAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
            (receivingAddress, registryAnchor, grantAmount, metadata) =
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

        // Check if recipient is reapplying after finishing a grant

        // Status.None can only be set if the recipient has distributed all their milestones
        // OR
        // Status.None can only be set if the recipient has not created a profile
        // A recipient with Status.None can only have milestones if they had distributed all their milestones
        // Therefore, we should delete existing milestone data if the recipient is reapplying
        if (milestones[recipientId].length > 0 && _recipients[recipientId].recipientStatus == Status.None) {
            delete milestones[recipientId];
            delete upcomingMilestone[recipientId];
        }

        // Create the recipient instance
        Recipient memory recipient = Recipient({
            receivingAddress: receivingAddress,
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

    /// @notice Allocate amount to GrantShip recipients
    /// @dev '_sender' must be a GameFacilitator to allocate. Emits 'RecipientStatusChanged() and 'Allocated()' events.
    /// @dev  Cannot allocate funds if there are unresolved red flags
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, Status recipientStatus, uint256 grantAmount, Metadata _reason)
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        noUnresolvedRedFlags
        onlyGameActive
        onlyGameFacilitator(_sender)
    {
        // Decode the '_data'
        (address recipientId, Status recipientStatus, uint256 grantAmount, Metadata memory _reason) =
            abi.decode(_data, (address, Status, uint256, Metadata));

        Recipient storage recipient = _recipients[recipientId];

        // : figure out why we need this check
        // Most grant managers would like to see a project's milestones before allocating funds
        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        if (recipient.recipientStatus != Status.Accepted && recipientStatus == Status.Accepted) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            allocatedGrantAmount += grantAmount;

            // Check if the allocated grant amount exceeds the pool amount and reverts if it does
            if (allocatedGrantAmount > poolAmount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }
            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = Status.Accepted;

            // Emit event for the acceptance
            emit RecipientStatusChanged(recipientId, Status.Accepted, _reason);

            // Emit event for the allocation
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (recipient.recipientStatus != Status.Rejected && recipientStatus == Status.Rejected) {
            recipient.recipientStatus = Status.Rejected;

            // Emit event for the rejection
            emit RecipientStatusChanged(recipientId, Status.Rejected, _reason);
        }
    }

    /// @notice Distribute the upcoming milestone to recipients.
    /// @dev '_sender' must be a pool manager to distribute.
    /// @dev Cannot distribute funds if there are unresolved red flags
    /// @param _recipientIds The recipient ids of the distribution
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        noUnresolvedRedFlags
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

        Recipient storage recipient = _recipients[_recipientId];

        // Ensure milestone exists
        if (milestoneToBeDistributed >= recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        if (milestone.milestoneStatus != Status.Pending) {
            revert INVALID_MILESTONE();
        }

        if (milestoneToBeDistributed == recipientMilestones.length - 1) {
            recipient.recipientStatus = Status.None;
            emit GrantComplete(_recipientId, recipient.grantAmount);
        }

        // Calculate the amount to be distributed for the milestone
        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        if (poolAmount < amount) {
            revert NOT_ENOUGH_FUNDS();
        }

        // Set the milestone status to 'Accepted'
        milestone.milestoneStatus = Status.Accepted;
        // Increment the upcoming milestone
        upcomingMilestone[_recipientId]++;

        // Get the pool, subtract the amount and transfer to the recipient
        IAllo.Pool memory pool = allo.getPool(poolId);
        poolAmount -= amount;
        allocatedGrantAmount -= amount;

        _transferAmount(pool.token, recipient.receivingAddress, amount);

        // Emit events for the milestone and the distribution
        emit MilestoneStatusChanged(_recipientId, milestoneToBeDistributed, Status.Accepted);
        emit Distributed(_recipientId, recipient.receivingAddress, amount, _sender);
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
        return PayoutSummary(recipient.receivingAddress, recipient.grantAmount);
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

            // Emit event for the milestone creation
            // needed for historical data
            emit MilestoneCreated(_recipientId, i, milestone.amountPercentage, milestone.metadata);
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
