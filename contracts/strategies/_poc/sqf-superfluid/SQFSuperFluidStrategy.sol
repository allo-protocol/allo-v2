// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {
    ISuperToken,
    ISuperfluidPool
} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {PoolConfig} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {SuperTokenV1Library} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IGitcoinPassportDecoder} from "./lib/IGitcoinPassportDecoder.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

// Interfaces
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {RecipientSuperApp} from "./RecipientSuperApp.sol";
import {RecipientSuperAppFactory} from "./RecipientSuperAppFactory.sol";

contract SQFSuperFluidStrategy is BaseStrategy, ReentrancyGuard {
    using SuperTokenV1Library for ISuperToken;
    using FixedPointMathLib for uint256;

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the recipients.
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        Status recipientStatus;
        Metadata metadata;
        RecipientSuperApp superApp;
    }

    /// @notice Stores the details needed for initializing strategy
    struct InitializeParams {
        bool useRegistryAnchor;
        bool metadataRequired;
        address passportDecoder;
        address superfluidHost;
        address allocationSuperToken;
        address recipientSuperAppFactory;
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 minPassportScore;
        uint256 initialSuperAppBalance;
    }

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
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when a recipient is reviewed
    /// @param recipientId ID of the recipient
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event Reviewed(address indexed recipientId, Status status, address sender);

    /// @notice Emitted when a recipient is canceled
    /// @param recipientId ID of the recipient
    /// @param sender The sender of the transaction
    event Canceled(address indexed recipientId, address sender);

    /// @notice Emitted when a minimum passport score is updated
    /// @param minPassportScore The new min passport score
    /// @param sender The sender of the transaction
    event MinPassportScoreUpdated(uint256 minPassportScore, address sender);

    // @notice Emitted when distribute is called
    // @param sender The sender of the transaction
    // @param flowRate The flow rate
    event Distributed(address indexed sender, int96 flowRate);

    /// @notice Emitted when the total units are updated
    /// @param recipientId ID of the recipient
    /// @param totalUnits The total units
    event TotalUnitsUpdated(address indexed recipientId, uint256 totalUnits);

    /// ================================
    /// ========== Storage =============
    /// ================================

    uint256 public initialSuperAppBalance;
    /// @dev Available at https://console.superfluid.finance/
    /// @notice The host contract for the superfluid protocol
    address public superfluidHost;

    /// @notice The pool super token
    ISuperToken public allocationSuperToken;
    ISuperToken public poolSuperToken;

    /// @notice The recipient SuperApp factory
    RecipientSuperAppFactory public recipientSuperAppFactory;

    /// @notice The GDA pool which streams pool tokens to recipients
    ISuperfluidPool public gdaPool;

    /// @notice The Gitcoin Passport Decoder
    IGitcoinPassportDecoder public passportDecoder;

    /// @notice The minimum passport score required to be an allocator
    uint256 public minPassportScore;

    /// @notice The start and end times for registration and allocation
    /// @dev The values will be in milliseconds since the epoch
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice Whether or not the strategy is using registry gating
    bool public useRegistryAnchor;

    /// @notice Whether or not the strategy requires metadata
    bool public metadataRequired;

    /// @notice The registry contract
    IRegistry private _registry;

    /// @notice The details of the recipient are returned using their ID
    /// @dev recipientId => Recipient
    mapping(address => Recipient) public recipients;

    /// @notice stores the recipienId of each superApp
    /// @dev superApp => recipientId
    mapping(address => address) public superApps;

    /// @notice stores the total units for each recipient
    /// @dev recipientId => units
    mapping(address => uint256) public totalUnitsByRecipient;

    /// @notice stores the flow rate for each recipient
    /// @dev recipientId => flowRate
    mapping(address => uint256) public recipientFlowRate;

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
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

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

        useRegistryAnchor = params.useRegistryAnchor;
        metadataRequired = params.metadataRequired;
        superfluidHost = params.superfluidHost;
        minPassportScore = params.minPassportScore;
        recipientSuperAppFactory = RecipientSuperAppFactory(params.recipientSuperAppFactory);
        _registry = allo.getRegistry();

        if (
            params.superfluidHost == address(0) || params.allocationSuperToken == address(0)
                || params.superfluidHost == address(0) || params.passportDecoder == address(0)
        ) revert ZERO_ADDRESS();

        if (params.initialSuperAppBalance == 0) revert INVALID();

        allocationSuperToken = ISuperToken(params.allocationSuperToken);
        poolSuperToken = ISuperToken(allo.getPool(poolId).token);
        allocationSuperToken.getUnderlyingToken();

        initialSuperAppBalance = params.initialSuperAppBalance;

        passportDecoder = IGitcoinPassportDecoder(params.passportDecoder);
        gdaPool = SuperTokenV1Library.createPool(
            poolSuperToken,
            address(this), // pool admin
            PoolConfig(
                /// @dev if true, the pool members can transfer their owned units
                /// else, only the pool admin can manipulate the units for pool members
                false,
                /// @dev if true, anyone can execute distributions via the pool
                /// else, only the pool admin can execute distributions via the pool
                true
            )
        );

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

    /// @notice Register Recipient to the pool
    /// @dev The '_data' parameter is encoded as follows:
    ///     - If useRegistryAnchor is true, then the data is encoded as (address recipientId, Metadata metadata)
    ///     - If useRegistryAnchor is false, then the data is encoded as (address recipientAddress, address registryAnchor, Metadata metadata)
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
        if (useRegistryAnchor) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            // when registry gating is enabled, the recipientId must be a profile member
            if (!_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        } else {
            (registryAnchor, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));
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
        recipient.useRegistryAnchor = useRegistryAnchor ? true : isUsingRegistryAnchor;

        Status currentStatus = recipient.recipientStatus;

        if (currentStatus == Status.None) {
            // recipient registering new application
            recipient.recipientStatus = Status.Pending;
            emit Registered(recipientId, _data, _sender);
        } else if (currentStatus == Status.Pending) {
            // emit the new status with the '_data' that was passed in
            emit UpdatedRegistration(recipientId, _data, _sender);
        } else {
            revert INVALID();
        }
    }

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        override
        onlyPoolManager(_sender)
    {
        _checkOnlyAfterRegistration();

        (int96 flowRate) = abi.decode(_data, (int96));
        poolSuperToken.distributeFlow(address(this), gdaPool, flowRate);

        emit Distributed(_sender, flowRate);
    }

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(bytes memory _data, address _sender) internal override onlyActiveAllocation {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        (address recipientId, int96 flowRate) = abi.decode(_data, (address, int96));

        Recipient storage recipient = recipients[recipientId];

        if (recipient.recipientStatus != Status.Accepted || address(recipient.superApp) == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        address superApp = address(recipient.superApp);
        (uint256 lastUpdated, int96 currentFlowRate,,) = allocationSuperToken.getFlowInfo(_sender, superApp);

        if (currentFlowRate == 0 || lastUpdated == 0) {
            // create the flow
            // enhancement: explore making a factory which would be approved by allocator only once
            allocationSuperToken.createFlowFrom(_sender, superApp, flowRate);
        } else {
            // update the flow
            allocationSuperToken.updateFlowFrom(_sender, superApp, flowRate);
        }

        emit Allocated(recipientId, uint256(int256(flowRate)), address(allocationSuperToken), _sender);
    }

    /// @notice This will get the flow rate for a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientId The ID of the recipient
    /// @return The payout summary for the recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        return PayoutSummary(recipients[_recipientId].recipientAddress, uint256(recipientFlowRate[_recipientId]));
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

    /// @notice Update the min passport score
    /// @param _minPassportScore The new min passport score
    function updateMinPassportScore(uint256 _minPassportScore) external onlyPoolManager(msg.sender) {
        minPassportScore = _minPassportScore;
        emit MinPassportScoreUpdated(_minPassportScore, msg.sender);
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        uint256 allocatorScore = passportDecoder.getScore(_allocator);
        if (allocatorScore >= minPassportScore) {
            return true;
        }
        return false;
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
                    || (recipientStatus != Status.Accepted && recipientStatus != Status.Rejected)
            ) {
                revert RECIPIENT_ERROR(recipientId);
            }
            recipient.recipientStatus = recipientStatus;

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            if (recipientStatus == Status.Accepted) {
                RecipientSuperApp superApp = recipientSuperAppFactory.createRecipientSuperApp(
                    recipient.recipientAddress, address(this), superfluidHost, allocationSuperToken, true, true, true
                );

                allocationSuperToken.transfer(address(superApp), initialSuperAppBalance);

                // Add recipientAddress as member of the GDA with 1 unit
                _updateMemberUnits(recipientId, recipient.recipientAddress, 1);

                superApps[address(superApp)] = recipientId;
                recipient.superApp = superApp;
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
        uint256 recipientLength = _recipientIds.length;

        for (uint256 i; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            // if the status is none or appealed then revert
            if (recipient.recipientStatus == Status.None || recipient.recipientStatus == Status.Canceled) {
                revert RECIPIENT_ERROR(recipientId);
            }

            recipient.recipientStatus = Status.Canceled;

            RecipientSuperApp recipientSuperApp = recipient.superApp;

            // Update mappings as recipient is cancelled
            delete recipient.superApp;
            delete superApps[address(recipientSuperApp)];
            delete recipientFlowRate[recipientId];

            // Set recipient units to 0 to stop streaming from GDA
            _updateMemberUnits(recipientId, recipient.recipientAddress, 0);

            emit Canceled(recipientId, msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Adjust the weightings of the recipients
    /// @dev This can only be called by the super app callback onFlowUpdated
    /// @param _previousFlowRate The previous flow rate
    /// @param _newFlowRate The new flow rate
    function adjustWeightings(uint256 _previousFlowRate, uint256 _newFlowRate) external {
        address recipientId = superApps[msg.sender];

        if (recipientId == address(0)) revert UNAUTHORIZED();

        uint256 recipientTotalUnits = totalUnitsByRecipient[recipientId] * 1e5;

        if (_previousFlowRate == 0) {
            // created a new flow
            uint256 scaledFlowRate = _newFlowRate / 1e6;

            if (scaledFlowRate > 0) {
                recipientTotalUnits = (recipientTotalUnits.sqrt() + scaledFlowRate.sqrt()) ** 2;
            }
        } else if (_newFlowRate == 0) {
            // canceled a flow
            uint256 scaledFlowRate = _previousFlowRate / 1e6;

            if (scaledFlowRate > 0) {
                recipientTotalUnits =
                    recipientTotalUnits + scaledFlowRate - 2 * uint256(recipientTotalUnits * scaledFlowRate).sqrt();
            }
        } else {
            // updated a flow
            uint256 scaledNewFlowRate = _newFlowRate / 1e6;
            uint256 scaledPreviousFlowRate = _previousFlowRate / 1e6;

            if (scaledNewFlowRate != scaledPreviousFlowRate) {
                if (scaledNewFlowRate > 0) {
                    recipientTotalUnits =
                        (recipientTotalUnits.sqrt() + scaledNewFlowRate.sqrt() - scaledPreviousFlowRate.sqrt()) ** 2;
                } else if (scaledPreviousFlowRate > 0) {
                    recipientTotalUnits = recipientTotalUnits + scaledPreviousFlowRate
                        - 2 * uint256(recipientTotalUnits * scaledPreviousFlowRate).sqrt();
                }
            }
        }

        recipientTotalUnits = recipientTotalUnits > 1e5 ? recipientTotalUnits / 1e5 : 1;

        Recipient storage recipient = recipients[recipientId];

        _updateMemberUnits(recipientId, recipient.recipientAddress, uint128(recipientTotalUnits));

        uint256 currentFlowRate = recipientFlowRate[recipientId];

        recipientFlowRate[recipientId] = currentFlowRate + _newFlowRate - _previousFlowRate;

        emit TotalUnitsUpdated(recipientId, recipientTotalUnits);
    }

    /// @notice Withdraw funds from the contract.
    /// @param _token Token to withdraw.
    /// @param _amount Amount to withdraw.
    function withdraw(address _token, uint256 _amount) external onlyPoolManager(msg.sender) {
        if (_token == address(poolSuperToken)) {
            revert INVALID();
        }
        _transferAmount(_token, msg.sender, _amount);
    }

    /// @notice Close the stream
    function closeStream() external onlyPoolManager(msg.sender) {
        poolSuperToken.distributeFlow(address(this), gdaPool, 0, "0x");
        _transferAmount(address(poolSuperToken), msg.sender, poolSuperToken.balanceOf(address(this)));
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

    /// @notice Check if the registration is active
    /// @dev Reverts if the registration is not active
    function _checkOnlyAfterRegistration() internal view virtual {
        if (block.timestamp < registrationEndTime) {
            revert REGISTRATION_ACTIVE();
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

    /// @notice Update the total units for a recipient
    /// @param _recipientId ID of the recipient
    /// @param _recipientAddress Address of the recipient
    /// @param _units The units
    function _updateMemberUnits(address _recipientId, address _recipientAddress, uint128 _units) internal {
        gdaPool.updateMemberUnits(_recipientAddress, _units);
        totalUnitsByRecipient[_recipientId] = _units;
        emit TotalUnitsUpdated(_recipientId, _units);
    }
}
