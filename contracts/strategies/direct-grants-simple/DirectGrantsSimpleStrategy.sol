// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Intefaces
import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

/// @title Direct Grants Simple Strategy
/// @notice A strategy is used to allocate & distribute funds to recipients with milestone payouts
/// @author allo-team
///
/// @dev This strategy is used to allocate & distribute funds to recipients with milestone payouts
contract DirectGrantsSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Enum to hold the internal status of the recipient
    /// @dev This status is specific to this strategy and is used to track the status of the recipient and milestones
    ///      Note: This is not the same as the global 'RecipientStatus' enum
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
        RecipientStatus milestonesReviewStatus;
    }

    /// @notice Struct to hold milestone details
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        RecipientStatus milestoneStatus;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when recipient is already accepted.
    error RECIPIENT_ALREADY_ACCEPTED();

    /// @notice Throws when the user address is not authorized.
    error UNAUTHORIZED();

    /// @notice Throws when the milestone is invalid.
    error INVALID_MILESTONE();

    /// @notice Throws when the milestone is already accepted.
    error MILESTONE_ALREADY_ACCEPTED();

    /// @notice Throws when the milestone is already rejected.
    //error MILESTONE_ALREADY_REJECTED();

    /// @notice Throws when the milestones are already set.
    error MILESTONES_ALREADY_SET();

    /// @notice Throws when the registration is invalid.
    error INVALID_REGISTRATION();

    /// @notice Throws when the allocation exceeds the pool amount.
    error ALLOCATION_EXCEEDS_POOL_AMOUNT();

    /// @notice Throws when the metadata is invalid.
    error INVALID_METADATA();

    /// @notice Throws when the recipient is not accepted.
    error RECIPIENT_NOT_ACCEPTED();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted for the registration of a recipient and the status is updated.
    event RecipientStatusChanged(address recipientId, InternalRecipientStatus status);

    /// @notice Emitted for the submission of a milestone.
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);

    /// @notice Emitted for the status change of a milestone.
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, RecipientStatus status);

    /// @notice Emitted for the milestones set.
    event MilestonesSet(address recipientId);
    event MilestonesReviewed(address recipientId, RecipientStatus status);

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public registryGating;
    bool public metadataRequired;
    bool public grantAmountRequired;
    uint256 public allocatedGrantAmount;
    IRegistry private _registry;

    /// @dev Internal collection of accepted recipients able to submit milestones
    address[] private _acceptedRecipientIds;

    /// @notice This maps accepted recipients to their details
    /// @dev Mapping of the 'recipientId' to the 'Recipient' struct
    mapping(address => Recipient) private _recipients;

    /// @notice This maps accepted recipients to their milestones
    /// @dev Mapping of the 'recipientId' to the 'Milestone' struct
    mapping(address => Milestone[]) public milestones;

    /// @notice This maps accepted recipients to their upcoming milestone
    /// @dev Mapping of the 'recipientId' to the 'nextMilestone' index
    mapping(address => uint256) public upcomingMilestone;

    /// @notice This maps accepted recipients to their total milestones
    // TODO: (payouts or count?) @thelostone-mc @KurtMerbeth
    // NOTE: Were not using this in the contract, but it is here for future use?
    // mapping(address => uint256) public totalMilestones;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Direct Grants Simple Strategy
    /// @dev Pass the Allo contract address for the network you choose and the name of the strategy
    ///      Note: The parameters just get passed on to the BaseStrategy
    /// @param _allo The address of the Allo contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool registryGating, bool metadataRequired, bool grantAmountRequired)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (bool _registryGating, bool _metadataRequired, bool _grantAmountRequired) =
            abi.decode(_data, (bool, bool, bool));
        __DirectGrantsSimpleStrategy_init(_poolId, _registryGating, _metadataRequired, _grantAmountRequired);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _poolId Id of the pool - required to initialize the BaseStrategy
    /// @param _registryGating Flag to check if registry gating is enabled
    /// @param _metadataRequired Flag to check if metadata is required
    /// @param _grantAmountRequired Flag to check if grant amount is required
    function __DirectGrantsSimpleStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        bool _grantAmountRequired
    ) internal {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        // Set the strategy specific variables
        registryGating = _registryGating;
        metadataRequired = _metadataRequired;
        _registry = allo.getRegistry();
        grantAmountRequired = _grantAmountRequired;

        // Set the pool to active - this is required for the strategy to work and distribute funds
        // NOTE: There may be some cases where you may want to not set this here, but will be strategy specific
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    /// @return Recipient Returns the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @dev This status is specific to this strategy and is used to track the status of the recipient
    /// @param _recipientId Id of the recipient
    /// @return InternalRecipientStatus Returns the internal recipient status specific to this strategy
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Get recipient status
    /// @dev The global 'RecipientStatus' is used at the protocol level and most strategies may want to
    ///      add a additional InternalRecipientStatus to track the status of the recipient and map back to
    ///      the global 'RecipientStatus'
    /// @param _recipientId Id of the recipient
    /// @return RecipientStatus Returns the global recipient status
    function _getRecipientStatus(address _recipientId) internal view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = _getRecipient(_recipientId).recipientStatus;
        if (internalStatus == InternalRecipientStatus.InReview) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// @notice Checks if address is elgible allocator
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return bool Returns true if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// @notice Get the status of the milestone of an recipient
    /// @dev This is used to check the status of the milestone of an recipient and is strategy specific
    /// @param _recipientId Id of the recipient
    /// @param _milestoneId Id of the milestone
    /// @return RecipientStatus Returns the status of the milestone using the 'RecipientStatus' enum
    function getMilestoneStatus(address _recipientId, uint256 _milestoneId) external view returns (RecipientStatus) {
        return milestones[_recipientId][_milestoneId].milestoneStatus;
    }

    /// @notice Get the milestones
    /// @param _recipientId Id of the recipient
    /// @return Milestone[] Returns the milestones for a 'recipientId'
    function getMilestones(address _recipientId) external view returns (Milestone[] memory) {
        return milestones[_recipientId];
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Set milestones for recipient
    /// @param _recipientId Id of the recipient
    /// @param _milestones The milestones to be set
    function setMilestones(address _recipientId, Milestone[] memory _milestones) external {
        bool isRecipientCreator = (msg.sender == _recipientId) || _isProfileMember(_recipientId, msg.sender);
        bool isPoolManager = allo.isPoolManager(poolId, msg.sender);
        if (!isRecipientCreator && !isPoolManager) {
            revert UNAUTHORIZED();
        }

        Recipient storage recipient = _recipients[_recipientId];

        // Check if the recipient is accepted, otherwise revert
        if (recipient.recipientStatus != InternalRecipientStatus.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        if (recipient.milestonesReviewStatus == RecipientStatus.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }

        _setMilestones(_recipientId, _milestones);

        if (isPoolManager) {
            recipient.milestonesReviewStatus = RecipientStatus.Accepted;
            emit MilestonesReviewed(_recipientId, RecipientStatus.Accepted);
        }
    }

    /// @notice Review the set milestones of the recipient
    /// @param _recipientId Id of the recipient
    /// @param _status The status of the milestone review
    function reviewSetMilestones(address _recipientId, RecipientStatus _status) external onlyPoolManager(msg.sender) {
        Recipient storage recipient = _recipients[_recipientId];

        if (milestones[_recipientId].length == 0) {
            revert INVALID_MILESTONE();
        }

        if (recipient.milestonesReviewStatus == RecipientStatus.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }
        if (_status == RecipientStatus.Accepted || _status == RecipientStatus.Rejected) {
            recipient.milestonesReviewStatus = _status;
            emit MilestonesReviewed(_recipientId, _status);
        }
    }

    /// @notice Submit milestone by the recipient
    ///
    /// Requirements: Must be a member of a 'Profile' to sumbit a milestone and '_recipientId'
    ///               must NOT be the same as 'msg.sender'
    ///
    /// @param _recipientId Id of the recipient
    /// @param _metadata The proof of work
    function submitMilestone(address _recipientId, uint256 _milestoneId, Metadata calldata _metadata) external {
        if (_recipientId != msg.sender && !_isProfileMember(_recipientId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        Recipient memory recipient = _recipients[_recipientId];
        if (recipient.recipientStatus != InternalRecipientStatus.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        Milestone[] storage recipientMilestones = milestones[_recipientId];

        // Check if the milestone is the upcoming one
        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        // Get the milestone using the '_milestoneId'
        Milestone storage milestone = recipientMilestones[_milestoneId];

        // Check if the milestone is accepted, otherwise revert
        if (milestone.milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        // Set the milestone metadata and status
        milestone.metadata = _metadata;
        milestone.milestoneStatus = RecipientStatus.Pending;

        // Emit event for the milestone submission
        emit MilestoneSubmitted(_recipientId, _milestoneId, _metadata);
    }

    /// @notice Reject pending milestone of the recipient
    ///
    /// Requirements: Only the pool manager can reject the milestone
    ///
    /// @param _recipientId Id of the recipient
    /// @param _milestoneId Id of the milestone
    function rejectMilestone(address _recipientId, uint256 _milestoneId) external onlyPoolManager(msg.sender) {
        Milestone[] storage recipientMilestones = milestones[_recipientId];
        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        if (milestone.milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        // Set the milestone status to 'Rejected'
        milestone.milestoneStatus = RecipientStatus.Rejected;

        // Emit event for the milestone rejection
        emit MilestoneStatusChanged(_recipientId, _milestoneId, RecipientStatus.Rejected);
    }

    /// @notice Set the internal status of the recipient to InReview
    /// @param _recipientIds Ids of the recipients
    function setInternalRecipientStatusToInReview(address[] calldata _recipientIds)
        external
        onlyPoolManager(msg.sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            _recipients[recipientId].recipientStatus = InternalRecipientStatus.InReview;

            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.InReview);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Withdraw funds from pool
    ///
    /// Requirements: Only the pool manager can withdraw
    ///
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        // Decrement the pool amount
        poolAmount -= _amount;

        // Transfer the amount to the pool manager
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @dev Register a recipient to the pool
    ///
    /// @param _data The data to be decoded
    /// @custom:data when 'registryGating' is 'true' -> (address recipientId, address recipientAddress, uint256 grantAmount, Metadata metadata)
    ///              when 'registryGating' is 'false' -> (address recipientAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    ///
    /// @return recipientId The id of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
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

            // Check if the registry anchor is valid so we know to use it or not
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
        if (_recipients[recipientId].recipientStatus == InternalRecipientStatus.Accepted) {
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
            recipientStatus: InternalRecipientStatus.Pending,
            milestonesReviewStatus: RecipientStatus.Pending
        });

        // Add the recipient to the accepted recipient ids mapping
        _recipients[recipientId] = recipient;

        // Emit event for the registration
        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Allocate amount to recipent for direct grants
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, InternalRecipientStatus recipientStatus, uint256 grantAmount)
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyPoolManager(_sender)
    {
        // Decode the '_data'
        (address recipientId, InternalRecipientStatus recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, InternalRecipientStatus, uint256));

        Recipient storage recipient = _recipients[recipientId];

        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        if (
            recipient.recipientStatus != InternalRecipientStatus.Accepted
                && recipientStatus == InternalRecipientStatus.Accepted
        ) {
            IAllo.Pool memory pool = allo.getPool(poolId);
            allocatedGrantAmount += grantAmount;

            // Check if the allocated grant amount exceeds the pool amount and reverts if it does
            if (allocatedGrantAmount > poolAmount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }

            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = InternalRecipientStatus.Accepted;

            // Emit event for the acceptance
            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Accepted);

            // Emit event for the allocation
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (
            recipient.recipientStatus != InternalRecipientStatus.Rejected // no need to reject twice
                && recipientStatus == InternalRecipientStatus.Rejected
        ) {
            recipient.recipientStatus = InternalRecipientStatus.Rejected;

            // Emit event for the rejection
            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Rejected);
        }
    }

    /// @dev Distribute the upcoming milestone to a array of recipients
    ///
    /// @param _recipientIds The recipient ids of the distribution
    /// @param _sender The sender of the distribution
    ///
    /// Requirements: Only the pool manager can distribute
    ///
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            _distributeUpcomingMilestone(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @dev Distribute the upcoming milestone
    ///
    /// @param _recipientId The recipient of the distribution
    /// @param _sender The sender of the distribution
    function _distributeUpcomingMilestone(address _recipientId, address _sender) private {
        uint256 milestoneToBeDistributed = upcomingMilestone[_recipientId];
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        Recipient memory recipient = _recipients[_recipientId];
        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        // check if milestone is not rejected or already paid out
        if (
            milestoneToBeDistributed > recipientMilestones.length
                || milestone.milestoneStatus != RecipientStatus.Pending
        ) {
            revert INVALID_MILESTONE();
        }

        // Calculate the amount to be distributed for the milestone
        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        // Get the pool, subtract the amount and transfer to the recipient
        IAllo.Pool memory pool = allo.getPool(poolId);

        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        // Set the milestone status to 'Accepted'
        milestone.milestoneStatus = RecipientStatus.Accepted;

        // Increment the upcoming milestone
        upcomingMilestone[_recipientId]++;

        // Emit events for the milestone and the distribution
        emit MilestoneStatusChanged(_recipientId, milestoneToBeDistributed, RecipientStatus.Accepted);
        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @dev Check if sender is profile owner or member
    ///
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    ///
    /// @return bool True if the sender is the owner or member of the profile, otherwise false
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @dev Get the recipient
    ///
    /// @param _recipientId Id of the recipient
    ///
    /// @return recipient Returns the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }

    /// @dev Get the payout summary for the accepted recipient
    ///
    /// @return PayoutSummary Returns the payout summary for the accepted recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _getRecipient(_recipientId);
        return PayoutSummary(recipient.recipientAddress, recipient.grantAmount);
    }

    /// @notice Set the milestones for the recipient
    /// @param _recipientId Id of the recipient
    /// @param _milestones The milestones to be set
    function _setMilestones(address _recipientId, Milestone[] memory _milestones) internal {
        uint256 totalAmountPercentage;

        // TODO: check if delete resets index to 0
        if (milestones[_recipientId].length > 0) {
            delete milestones[_recipientId];
        }

        uint256 milestonesLength = _milestones.length;
        for (uint256 i = 0; i < milestonesLength;) {
            Milestone memory milestone = _milestones[i];
            if (milestone.milestoneStatus != RecipientStatus.None) {
                revert INVALID_MILESTONE();
            }
            totalAmountPercentage += milestone.amountPercentage;
            milestones[_recipientId].push(milestone);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONE();
        }

        emit MilestonesSet(_recipientId);
    }

    receive() external payable {}
}
