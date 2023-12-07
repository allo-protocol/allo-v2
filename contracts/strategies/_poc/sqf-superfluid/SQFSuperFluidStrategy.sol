// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {
    // ISuperfluid,
    ISuperToken,
    // ISuperApp,
    // SuperAppDefinitions GeneralDistributionAgreementV1
} from "@superfluid-finance/interfaces/superfluid/ISuperfluid.sol";
// Interfaces
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {SuperAppBaseSQF} from "./SuperAppBaseSQF.sol";
import {RecipientSuperApp} from "./RecipientSuperApp.sol";


contract SQFSuperFluidStrategy is BaseStrategy, ReentrancyGuard {
    error INSUFFICIENT_FUNDS();

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when the pool timestamps are updated
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event TimestampsUpdated(
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 allocationStartTime,
        uint64 allocationEndTime,
        address sender
    );

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId ID of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    /// @param status The updated status of the recipient
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, Status status);

    /// @notice Emitted when a recipient is reviewed
    /// @param recipientId ID of the recipient
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event Reviewed(address indexed recipientId, Status status, address sender);

    /// @notice Emitted when a recipient is canceled
    /// @param recipientId ID of the recipient
    /// @param sender The sender of the transaction
    event Canceled(address indexed recipientId, address sender);

    /// @notice Stores the details of the recipients.
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Status recipientStatus;
        Metadata metadata;
        RecipientSuperApp superApp;
    }

    /// @notice The parameters used to initialize the strategy
    struct InitializeParams {
        bool registryGating;
        bool metadataRequired;
        address superfluidHost;
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
    }

    ISuperToken public superToken;

    // can be found on https://console.superfluid.finance/
    address public superfluidHost;
    address public GDA;

    /// @notice The start and end times for registrations and allocations
    /// @dev The values will be in milliseconds since the epoch
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice Whether or not the strategy is using registry gating
    bool public registryGating;

    /// @notice Whether or not the strategy requires metadata
    bool public metadataRequired;

    /// @notice The registry contract
    IRegistry private _registry;

    address superfluidHost;

    /// @notice The details of the recipient are returned using their ID
    /// @dev recipientId => Recipient
    mapping(address => Recipient) public recipients;

    /// @notice stores the recipienId of each superApp
    /// @dev superApp => recipientId
    mapping(address => address) public superApps;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the registration is active
    /// @dev Reverts if the registration is not active
    modifier onlyActiveRegistration() {
        _checkOnlyActiveRegistration();
        _;
    }

    /// @notice Modifier to check if the allocation is active
    /// @dev Reverts if the allocation is not active
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// @notice Modifier to check if the allocation has ended
    /// @dev This will revert if the allocation has ended.
    modifier onlyBeforeAllocationEnds() {
        _checkOnlyBeforeAllocationEnds();
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Micro Grants Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name, ISuperfluid _host) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    function initialize(uint256 _poolId, bytes memory _data) external override {
        (InitializeParams memory params) = abi.decode(_data, (InitializeParams));

        // Initialize the BaseStrategy with the '_poolId'
        __BaseStrategy_init(_poolId);

        registryGating = params.registryGating;
        metadataRequired = params.metadataRequired;
        superfluidHost = params.superfluidHost;
        _registry = allo.getRegistry();

        if (params.superfluidHost == address(0)) revert ZERO_ADDRESS();
        superfluidHost = params.superfluidHost;

        superToken = ISuperToken(allo.getPool(_poolId).token);
        //todo: check if token is a super token

        _updatePoolTimestamps(
            params.registrationStartTime,
            params.registrationEndTime,
            params.allocationStartTime,
            params.allocationEndTime
        );
    }

    /// ====================================
    /// ============== Main ================
    /// ====================================

    /// @notice Submit application to pool
    /// @dev The '_data' parameter is encoded as follows:
    ///     - If registryGating is true, then the data is encoded as (address recipientId, Metadata metadata)
    ///     - If registryGating is false, then the data is encoded as (address recipientAddress, address registryAnchor, Metadata metadata)
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    /// @return recipientId The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;

        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, metadata) = abi.decode(_data, (address, Metadata));

            // The profile’s anchor address should be used to receive funds
            recipientAddress = recipientId;
            // when registry gating is enabled, the recipientId must be a profile member
            if (!_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

            // when using registry anchor, the ID of the recipient must be a profile member
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        }

        // make sure that if metadata is required, it is provided
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // make sure the recipient address is not the zero address
        if (recipientAddress == address(0)) revert RECIPIENT_ERROR(recipientId);

        Recipient storage recipient = recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = registryGating ? true : isUsingRegistryAnchor;

        Status currentStatus = recipient.recipientStatus;

        if (currentStatus == Status.None) {
            // recipient registering new application
            recipient.recipientStatus = Status.Pending;
            emit Registered(recipientId, _data, _sender);
        } else {
            if (currentStatus == Status.Pending) {
                // emit the new status with the '_data' that was passed in
                // todo: do we need the updated event? do we need the status?
                emit UpdatedRegistration(recipientId, _data, _sender, recipient.recipientStatus);
            } else {
                revert INVALID();
            }
        }
    }

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        override
        onlyAfterAllocation
    {
        // todo:
        // decode the data ()?
        (ISuperToken _superToken) = abi.decode(_data, (ISuperToken));
        uint256 superTokenBalance = _superToken.balanceOf(address(this));

        // (uint256 actualDistributionAmount,) =
        //     superToken.calculateDistribution(address(this), INDEX_ID, superTokenBalance);

        // superToken.distribute(INDEX_ID, 1);

        // check if the pool has enough funds to distribute
        // if (allo.getPoolBalance(poolId) < totalAmount) revert INSUFFICIENT_FUNDS();

        // the program managers will call distribute(),
        // which will create the GDA and start distributing

        // to all approved recipients.

        // If at that time, no CFAs have been created through allocate(),
        // then the GDA will be distributed evenly among all approved recipients
    }

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(bytes memory _data, address _sender) internal override onlyActiveAllocation {
        (address recipientId, int96 flowRate) = abi.decode(_data, (address, int96));

        Recipient storage recipient = recipients[recipientId];

        if (recipient.recipientStatus != Status.Accepted || address(recipient.superApp) == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        address superApp = address(recipient.superApp);
        (uint256 lastUpdated, int96 flowRate,,) = superToken.getFlowInfo(_sender, superApp);

        // if the flowRate or lastUpdated is 0, then this is a new flow
        if (flowRate == 0 || lastUpdated == 0) {
            superToken.createFlowFrom(_sender, superApp, flowRate);
        
        } else {
            // this is an update to an existing flow
            superToken.updateFlowFrom(_sender, superApp, flowRate);
        }
    }

    /// @notice This will get the payout summary for a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientId The ID of the recipient
    /// @param _data The data to use to get the payout summary for the recipient
    /// @return The payout summary for the recipient
    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        override
        returns (PayoutSummary memory)
    {
        // todo
        // discuss what to return here
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        _updatePoolTimestamps(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        // todo: check passport
        _allocator;
        return true;
    }

    /// @notice Review recipient(s) application(s)
    /// @dev You can review multiple recipients at once or just one. This can only be called by a pool manager and
    ///      only during active registration.
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, Status[] calldata _recipientStatuses)
        external
        virtual
        onlyPoolManager(msg.sender)
        onlyBeforeAllocationEnds
    {
        // make sure the arrays are the same length
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) revert INVALID();

        for (uint256 i; i < recipientLength;) {
            Status recipientStatus = _recipientStatuses[i];
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            // only pending applications can be updated
            // and the new status can only be Accepted or Rejected
            if (
                recipient.recipientStatus != Status.Pending
                    && (recipientStatus != Status.Accepted && recipientStatus != Status.Rejected)
            ) {
                revert RECIPIENT_ERROR(recipientId);
            }
            recipient.recipientStatus = recipientStatus;

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            if (recipientStatus == Status.Accepted) {
                //todo: think about creating a clone instead
                RecipientSuperApp superApp = new RecipientSuperApp(
                    address(this),
                    superfluidHost,
                    true,
                    true,
                    true,
                    "TheRegistrationKey" // todo
                );

                superApps[address(superApp)] = recipientId;
                recipient.superApp = superApp;
                // allocate 1 unit
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Cancel (remove) recipient(s) application(s)
    /// @dev You can remove multiple recipients at once or just one.
    /// @param _recipientIds Ids of the recipients
    function cancelRecipients(address[] calldata _recipientIds)
        external
        virtual
        onlyPoolManager(msg.sender)
        onlyBeforeAllocationEnds
    {
        for (uint256 i; i < _recipientIds.length;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            // if the status is none or appealed then revert
            if (recipient.recipientStatus == Status.None) {
                revert RECIPIENT_ERROR(recipientId);
            }

            recipient.recipientStatus = Status.Canceled;

            RecipientSuperApp recipientSuperApp = recipient.superApp;

            delete recipient.superApp;
            delete superApps[address(recipientSuperApp)];

            // todo: update/remove from GDA

            emit Canceled(recipientId, msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    function adjustWeightings(int96 _previousFlowrate, int96 _newFlowRate) external virtual {
        if (superApps[msg.sender] == address(0)) revert UNAUTHORIZED();

        _previousFlowrate;
        _newFlowRate;
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return The recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get the recipientId of a super app
    /// @param _superApp The super app
    /// @return The recipientId
    function getRecipientId(address _superApp) external view returns (address) {
        return superApps[_superApp];
    }

    /// @notice Get the super app of a recipient
    /// @param _recipientId The ID of the recipient
    /// @return The super app
    function getSuperApp(address _recipientId) external view returns (RecipientSuperApp) {
        return recipients[_recipientId].superApp;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Getter for a recipient using the ID
    /// @param _recipientId ID of the recipient
    /// @return The recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return recipients[_recipientId];
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Checks if a pool is active or not
    /// @return Whether the pool is active or not
    function _isPoolActive() internal view virtual override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Check if the registration is active
    /// @dev Reverts if the registration is not active
    function _checkOnlyActiveRegistration() internal view virtual {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the allocation is active
    /// @dev Reverts if the allocation is not active
    function _checkOnlyActiveAllocation() internal view virtual {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    function _checkOnlyAfterAllocation() internal view virtual {
        if (block.timestamp <= allocationEndTime) revert ALLOCATION_NOT_ENDED();
    }

    /// @notice Checks if the allocation has not ended and reverts if it has.
    /// @dev This will revert if the allocation has ended.
    function _checkOnlyBeforeAllocationEnds() internal view {
        if (block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) internal {
        // validate the timestamps for this strategy
        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        // Set the new values
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // emit the event
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// @notice Check if sender is a profile member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return If the '_sender' is a profile member
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    // todo: remove these helpers if they don't seem productive...

    /// @notice Send a lump sum of super tokens into the contract.
    /// @dev This requires a super token ERC20 approval.
    /// @param token Super Token to transfer.
    /// @param amount Amount to transfer.
    function sendLumpSumToContract(ISuperToken token, uint256 amount) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        token.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Create a stream into the contract.
    /// @dev This requires the contract to be a flowOperator for the msg sender.
    /// @param token Token to stream.
    /// @param flowRate Flow rate per second to stream.
    function createFlowIntoContract(ISuperToken token, int96 flowRate) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.createFlowFrom(msg.sender, address(this), flowRate);
    }

    /// @notice Update an existing stream being sent into the contract by msg sender.
    /// @dev This requires the contract to be a flowOperator for the msg sender.
    /// @param token Token to stream.
    /// @param flowRate Flow rate per second to stream.
    function updateFlowIntoContract(ISuperToken token, int96 flowRate) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.updateFlowFrom(msg.sender, address(this), flowRate);
    }

    /// @notice Delete a stream that the msg.sender has open into the contract.
    /// @param token Token to quit streaming.
    function deleteFlowIntoContract(ISuperToken token) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.deleteFlow(msg.sender, address(this));
    }

    /// @notice Withdraw funds from the contract.
    /// @param token Token to withdraw.
    /// @param amount Amount to withdraw.
    function withdrawFunds(ISuperToken token, uint256 amount) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        token.transfer(msg.sender, amount);
    }

    /// @notice Create flow from contract to specified address.
    /// @param token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param flowRate Flow rate per second to stream.
    function createFlowFromContract(ISuperToken token, address receiver, int96 flowRate) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.createFlow(receiver, flowRate);
    }

    /// @notice Update flow from contract to specified address.
    /// @param token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param flowRate Flow rate per second to stream.
    function updateFlowFromContract(ISuperToken token, address receiver, int96 flowRate) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.updateFlow(receiver, flowRate);
    }

    /// @notice Delete flow from contract to specified address.
    /// @param token Token to stop streaming.
    /// @param receiver Receiver of stream.
    function deleteFlowFromContract(ISuperToken token, address receiver) internal {
        // if (!recipients[msg.sender]) revert UNAUTHORIZED();

        // token.deleteFlow(address(this), receiver);
    }
}
