// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../../core/IAllo.sol";
import {IRegistry} from "../../../core/IRegistry.sol";
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";

contract QVSimpleStrategy is BaseStrategy {
    /// ======================
    /// ======= Errors ======
    /// ======================

    error QVSimple_ALLOCATION_WINDOW_CLOSED();
    error QVSimple_ALLOCATION_WINDOW_OPEN();
    error QVSimple_ALREADY_ACCEPTED();
    error QVSimple_IDENTITY_REQUIRED();
    error QVSimple_NOT_ACCEPTED();
    error QVSimple_NOT_ENOUGH_VOICE_CREDITS();

    /// ======================
    /// ======= Events =======
    /// ======================

    event MetadataUpdated(address indexed recipientId, Metadata metadata, address sender);

    /// ======================
    /// ======= Storage ======
    /// ======================

    enum Status {
        None,
        Pending,
        Accepted,
        Appealed,
        Rejected
    }

    // Note: still need to figure out the best way to store the votes and applications @thelostone-mc @KurtMerbeth
    struct Recipient {
        bytes identityId;
        address payoutAddress;
    }

    struct Allocator {
        address allocator;
        uint256 voiceCredits;
    }

    struct Allocation {
        address allocator;
        uint256 numVoiceCredits;
    }

    struct Application {
        address applicant;
        bytes metadata;
        uint256[] votes;
        RecipientStatus status;
    }

    // recipientId => Recipient
    mapping(address => Recipient) public recipients;

    // applicant => Application
    mapping(address => Application) public applications;

    // recipientId => Allocation
    mapping(address => Allocation) public allocations;

    // allocator => bool
    mapping(address => bool) public eligibleAllocators;

    // allocator => voiceCredits
    mapping(address => uint256) public voiceCredits;

    // Note: need to map local status to global status
    // recipientId => Status
    mapping(address => Status) public status;

    uint256 public applicationWindowStartTime;
    uint256 public applicationWindowEndTime;
    uint256 public allocationWindowStartTime;
    uint256 public allocationWindowEndTime;
    uint256 public voiceCreditsPerAllocator;

    bool public identityRequired;
    bool public metadataRequired;
    bool public payoutReady;

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if the caller is a pool admin
    modifier onlyAdmin() {
        if (!allo.isPoolAdmin(poolId, msg.sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the caller is a pool manager
    modifier onlyManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    constructor(address _alloContract, uint256 _poolId) BaseStrategy(_alloContract, "QVSimple") {
        poolId = _poolId;
    }

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public override {
        __QVSimpleStrategy_init(_poolId, _data);
    }

    /// @dev Internal initialize function that sets the poolId in the base strategy
    function __QVSimpleStrategy_init(uint256 _poolId, bytes memory _data) internal {
        // Set up the strategy
        (
            identityRequired,
            metadataRequired,
            voiceCreditsPerAllocator,
            applicationWindowStartTime,
            applicationWindowEndTime,
            allocationWindowStartTime,
            allocationWindowEndTime
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, uint256));

        // initialize the base strategy with the poolId
        super.__BaseStrategy_init(_poolId);
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the recipient status
    /// @param _recipientId The recipient id
    /// @return The recipient status
    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus) {
        return applications[_recipientId].status;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view returns (bool) {
        return eligibleAllocators[_allocator];
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Set the metadata for the recipient
    /// @param _recipientId The recipient id
    /// @param _metadata The metadata as a Metadata struct
    function setMetadata(address _recipientId, Metadata memory _metadata) external onlyPoolManager(msg.sender) {
        Application storage application = applications[_recipientId];
        application.metadata = abi.encode(_metadata);

        emit MetadataUpdated(_recipientId, _metadata, msg.sender);
    }

    /// @notice Set the status for the recipient
    /// @param _recipientId The recipient id
    /// @param _status The status
    /// @dev only callable by pool manager
    function setApplicationStatus(address _recipientId, RecipientStatus _status) external onlyPoolManager(msg.sender) {
        // Note: do we want any checks on this?
        Application storage application = applications[_recipientId];
        application.status = _status;
        // todo: set the local status here
        // status[_recipientId] =
    }

    /// @notice Get the payouts for the recipients
    /// @param _recipientIds The recipient ids
    /// @return The payouts as an array of PayoutSummary structs
    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        override
        returns (PayoutSummary[] memory)
    {
        // Calculate the total number of votes per recipient
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            totalVotes += _calculateVotes(applications[_recipientIds[i]].votes.length);
        }

        // Calculate the payout amounts for each recipient based on their votes
        PayoutSummary[] memory payouts = new PayoutSummary[](_recipientIds.length);
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            address recipientId = _recipientIds[i];
            uint256 votes = _calculateVotes(applications[recipientId].votes.length);

            // Calculate the payout amount based on the percentage of total votes
            uint256 amount = _calculatePayoutAmount(totalVotes, votes);

            payouts[i] = PayoutSummary(recipientId, amount);
        }

        return payouts;
    }

    /// @notice Apply to become a recipient - Register the recipient
    /// @param _data The data
    /// @param _applicant The applicant address
    /// @return recipientId
    function applyAndRegister(bytes memory _data, address _applicant) external returns (address recipientId) {
        if (identityRequired) {
            // Note: update the anchor address here?
            if (!_isIdentityMember(_applicant, _applicant)) {
                revert QVSimple_IDENTITY_REQUIRED();
            }
        }

        // Recipient storage recipient = recipients[_applicant];
        Application storage application = applications[_applicant];

        if (application.status == RecipientStatus.Pending) {
            // update application info and do nothing else
        }
        if (application.status == RecipientStatus.Accepted) {
            // Note: per spec - update application info and set to pending
            application.status = RecipientStatus.Pending;
            status[_applicant] = Status.Pending;
            // why not this?
            // revert QVSimple_ALREADY_ACCEPTED();
        }
        if (application.status == RecipientStatus.Rejected) {
            application.status = RecipientStatus.Pending;
            status[_applicant] = Status.Appealed;
        }

        // register the recipient
        recipientId = _registerRecipient(_data, _applicant);
    }

    /// @notice Allocate votes to a recipient
    /// @param _allocationData The metadata
    function allocate(Allocation memory _allocationData) external {
        (address recipientId, uint256 numVoiceCredits) = (_allocationData.allocator, _allocationData.numVoiceCredits);

        // - check if the allocation window is open
        if (allocationWindowStartTime > block.timestamp || block.timestamp > allocationWindowEndTime) {
            revert QVSimple_ALLOCATION_WINDOW_CLOSED();
        }
        // - check if the sender is eligible to allocate
        if (!eligibleAllocators[msg.sender]) {
            revert BaseStrategy_UNAUTHORIZED();
        }

        // - check if the recipient is accepted
        // Recipient storage recipient = recipients[recipientId];
        Application storage application = applications[recipientId];
        if (application.status != RecipientStatus.Accepted) {
            revert QVSimple_NOT_ACCEPTED();
        }

        // - check if the sender has enough voice credits to allocate
        if (voiceCredits[msg.sender] < numVoiceCredits) {
            revert QVSimple_NOT_ENOUGH_VOICE_CREDITS();
        }
        allocations[recipientId] = Allocation(recipientId, numVoiceCredits);

        bytes memory allocationData = abi.encode(_allocationData);

        _allocate(allocationData, msg.sender);
    }

    /// @notice Set the start and end dates for the application and allocation windows
    /// @param _data The data
    function setStartAndEndDates(bytes memory _data) external onlyPoolManager(msg.sender) {
        (applicationWindowStartTime, applicationWindowEndTime, allocationWindowStartTime, allocationWindowEndTime) =
            abi.decode(_data, (uint256, uint256, uint256, uint256));
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Register the recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @return recipientId
    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address) {
        // Recipient storage recipient = recipients[_sender];
        Application storage application = applications[_sender];

        // update recipient status
        application.status = RecipientStatus.Pending;
        application.metadata = _data;

        // add to eligible allocators
        eligibleAllocators[_sender] = true;

        emit Registered(_sender, _data, msg.sender);

        // todo: return the recipientId here
        // Note: not sure if we should be using the sender address as the recipientId here?
        return _sender;
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override onlyPoolManager(_sender) {
        (, address recipientId) = abi.decode(_data, (PayoutSummary, address));

        // Recipient storage recipient = recipients[recipientId];
        Application storage application = applications[recipientId];
        if (application.status != RecipientStatus.Accepted) {
            revert QVSimple_NOT_ACCEPTED();
        }

        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than zero");

        uint256 remainingVoiceCredits = voiceCredits[msg.sender];
        require(remainingVoiceCredits >= amount, "Insufficient voice credits");

        uint256 votes = _calculateVotes(amount);
        application.votes.push(votes + 1);
        voiceCredits[msg.sender] -= amount;

        emit Allocated(_sender, amount, address(0), msg.sender);
    }

    /// @notice Distribute funds to the recipients
    /// @param _recipientIds The recipient ids
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        override
        onlyPoolManager(_sender)
    {
        // make sure pool is Active
        if (!poolActive) {
            revert BaseStrategy_POOL_INACTIVE();
        }
        // make sure the application/allocation windows are closed and
        if (allocationWindowEndTime < block.timestamp || block.timestamp < applicationWindowStartTime) {
            revert();
        }

        uint256 numberOfRecipients = _recipientIds.length;
        Recipient memory recipient;
        Application storage application;
        for (uint256 i; numberOfRecipients > i;) {
            application = applications[_recipientIds[i]];
            recipient = recipients[_recipientIds[i]];
            if (application.status != RecipientStatus.Accepted) {
                revert QVSimple_NOT_ACCEPTED();
            }
            // make the payouts

            unchecked {
                i++;
            }
        }
    }

    function _calculateVotes(uint256 amount) internal pure returns (uint256) {
        return _sqrt(amount);
    }

    function _calculatePayoutAmount(uint256 totalVotes, uint256 recipientVotes) internal pure returns (uint256) {
        // Calculate the percentage of total votes
        uint256 percentage = (recipientVotes * 100) / totalVotes;
        // Calculate the payout amount based on the percentage of total pool funds
        // ...

        return percentage;
    }

    /// @notice Check if sender is identity owner or member
    /// @param _anchor Anchor of the identity
    /// @param _sender The sender of the transaction
    function _isIdentityMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isMemberOfIdentity(identity.id, _sender);
    }

    /// @notice Calculate the square root of a number
    /// @param x The number
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculate the square root of a number in wei
    /// @param weiX The number in wei
    // Note: overflow is not checked and can occur if weiX is too large
    function _sqrtWei(uint256 weiX) internal pure returns (uint256 weiY) {
        // Convert to "fixed-point" representation with 18 decimal places
        uint256 x = weiX * 1e18;
        uint256 y = _sqrt(x);
        // Convert back to wei
        return y / 1e9;
    }
}
