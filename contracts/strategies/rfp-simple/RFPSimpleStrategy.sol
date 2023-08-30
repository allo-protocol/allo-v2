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

contract RFPSimpleStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Struct to hold details of a recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 proposalBid;
        RecipientStatus recipientStatus;
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

    error INVALID_MILESTONE();
    error MILESTONE_ALREADY_ACCEPTED();
    error EXCEEDING_MAX_BID();
    error MILESTONES_ALREADY_SET();
    error AMOUNT_TOO_LOW();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event MaxBidIncreased(uint256 maxBid);
    event MilstoneSubmitted(uint256 milestoneId);
    event MilestoneRejected(uint256 milestoneId);
    event MilestonesSet();

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public useRegistryAnchor;
    bool public metadataRequired;
    address public acceptedRecipientId;
    IRegistry private _registry;
    uint256 public maxBid;
    uint256 public upcomingMilestone;

    address[] private _recipientIds;
    Milestone[] public milestones;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) internal _recipients;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (uint256 _maxBid, bool _useRegistryAnchor, bool _metadataRequired) = abi.decode(_data, (uint256, bool, bool));
        __RFPSimpleStrategy_init(_poolId, _maxBid, _useRegistryAnchor, _metadataRequired);
    }

    function __RFPSimpleStrategy_init(uint256 _poolId, uint256 _maxBid, bool _useRegistryAnchor, bool _metadataRequired)
        internal
    {
        __BaseStrategy_init(_poolId);
        useRegistryAnchor = _useRegistryAnchor;
        metadataRequired = _metadataRequired;
        _setPoolActive(true);
        _increaseMaxBid(_maxBid);
        _registry = allo.getRegistry();
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (RecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory, bytes[] memory) external view override returns (PayoutSummary[] memory) {
        PayoutSummary[] memory payouts = new PayoutSummary[](1);
        payouts[0] = _getPayout(acceptedRecipientId, "");

        return payouts;
    }

    /// @notice Get the milestone
    /// @param _milestoneId Id of the milestone
    function getMilestone(uint256 _milestoneId) external view returns (Milestone memory) {
        return milestones[_milestoneId];
    }

    /// @notice Get the status of the milestone
    /// @param _milestoneId Id of the milestone
    function getMilestoneStatus(uint256 _milestoneId) external view returns (RecipientStatus) {
        return milestones[_milestoneId].milestoneStatus;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    function setPoolActive(bool _active) external {
        _setPoolActive(_active);
    }

    /// @notice Set milestones for RFP pool
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

    /// @notice Submit milestone to RFP pool
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

    /// @notice Reject pending milestone
    /// @param _milestoneId Id of the milestone
    function rejectMilestone(uint256 _milestoneId) external onlyPoolManager(msg.sender) {
        if (milestones[_milestoneId].milestoneStatus == RecipientStatus.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        milestones[_milestoneId].milestoneStatus = RecipientStatus.Rejected;
        emit MilestoneRejected(_milestoneId);
    }

    /// @notice Withdraw funds from RFP pool
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
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        uint256 proposalBid;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (useRegistryAnchor) {
            (recipientId, proposalBid, metadata) = abi.decode(_data, (address, uint256, Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, proposalBid, metadata) =
                abi.decode(_data, (address, address, uint256, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // check if proposal bid is less than max bid
        if (proposalBid > maxBid) {
            revert EXCEEDING_MAX_BID();
        } else if (proposalBid == 0) {
            proposalBid = maxBid;
        }

        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            useRegistryAnchor: useRegistryAnchor ? true : isUsingRegistryAnchor,
            proposalBid: proposalBid,
            recipientStatus: RecipientStatus.Pending
        });

        _recipients[recipientId] = recipient;
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

    /// @notice Distribute the upcoming milestone
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory, bytes memory, address _sender)
        internal
        virtual
        override
        onlyInactivePool
        onlyPoolManager(_sender)
    {
        if (upcomingMilestone >= milestones.length) {
            revert INVALID_MILESTONE();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        Milestone storage milestone = milestones[upcomingMilestone];
        Recipient memory recipient = _recipients[acceptedRecipientId];

        if (recipient.proposalBid > poolAmount) {
            revert NOT_ENOUGH_FUNDS();
        }

        uint256 amount = (recipient.proposalBid * milestone.amountPercentage) / 1e18;

        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        milestone.milestoneStatus = RecipientStatus.Accepted;
        upcomingMilestone++;

        emit Distributed(acceptedRecipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @notice Check if the sender is a profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];

        if (acceptedRecipientId != address(0) && acceptedRecipientId != _recipientId) {
            recipient.recipientStatus =
                recipient.recipientStatus > RecipientStatus.None ? RecipientStatus.Rejected : RecipientStatus.None;
        }
    }

    /// @notice Update max bid for RFP pool
    /// @param _maxBid The max bid to be set
    function _increaseMaxBid(uint256 _maxBid) internal {
        if (_maxBid < maxBid) {
            revert AMOUNT_TOO_LOW();
        }
        maxBid = _maxBid;

        emit MaxBidIncreased(maxBid);
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _recipients[_recipientId];
        return PayoutSummary(recipient.recipientAddress, recipient.proposalBid);
    }

    /// @notice Checks if address is eligible allocator
    /// @param _allocator Address of the allocator
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    receive() external payable {}
}
