// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {
    ISuperToken,
    ISuperfluidPool
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IGitcoinPassportDecoder} from "contracts/strategies/interfaces/IGitcoinPassportDecoder.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {IRecipientSuperAppFactory} from "contracts/strategies/interfaces/IRecipientSuperAppFactory.sol";

// Core Contracts
import {RecipientsExtension} from "contracts/extensions/contracts/RecipientsExtension.sol";
import {CoreBaseStrategy} from "contracts/strategies/CoreBaseStrategy.sol";

contract SQFSuperFluidStrategy is CoreBaseStrategy, RecipientsExtension {
    using SuperTokenV1Library for ISuperToken;
    using FixedPointMathLib for uint256;

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details needed for initializing strategy
    struct SQFSuperfluidInitializeParams {
        address passportDecoder;
        address superfluidHost;
        address allocationSuperToken;
        address recipientSuperAppFactory;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 minPassportScore;
        uint256 initialSuperAppBalance;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when the pool timestamps are updated
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event AllocationTimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);

    // /// @notice Emitted when a recipient updates their registration
    // /// @param recipientId ID of the recipient
    // /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    // /// @param sender The sender of the transaction
    // event UpdatedRegistration(address indexed recipientId, bytes data, address sender);

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

    /// @notice Emitted when the total units are updated
    /// @param recipientId ID of the recipient
    /// @param totalUnits The total units
    event TotalUnitsUpdated(address indexed recipientId, uint256 totalUnits);

    /// ======================
    /// ======= Errors =======
    /// ======================

    /// @notice Thrown when the timestamps being set or updated don't meet the contracts requirements.
    error INVALID_TIMESTAMPS();

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
    IRecipientSuperAppFactory public recipientSuperAppFactory;

    /// @notice The GDA pool which streams pool tokens to recipients
    ISuperfluidPool public gdaPool;

    /// @notice The Gitcoin Passport Decoder
    IGitcoinPassportDecoder public passportDecoder;

    /// @notice The minimum passport score required to be an allocator
    uint256 public minPassportScore;

    /// @notice The start and end times for allocation
    /// @dev The values will be in milliseconds since the epoch
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice stores the superApp of each recipientId
    mapping(address => address) public recipientIdSuperApps;

    /// @notice stores the recipientId of each superApp
    mapping(address => address) public superAppsRecipientIds;

    /// @notice stores the total units for each recipient
    /// @dev recipientId => units
    mapping(address => uint256) public totalUnitsByRecipient;

    /// @notice stores the flow rate for each recipient
    /// @dev recipientId => flowRate
    mapping(address => uint256) public recipientFlowRate;

    /// ================================
    /// ========== Modifier ============
    /// ================================

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
    constructor(address _allo) RecipientsExtension(_allo, true) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    function initialize(uint256 _poolId, bytes memory _data) external override {
        (
            RecipientInitializeData memory _recipientExtensionInitializeData,
            SQFSuperfluidInitializeParams memory _sqfSuperfluidInitializeParams
        ) = abi.decode(_data, (RecipientInitializeData, SQFSuperfluidInitializeParams));

        // Initialize the BaseStrategy with the '_poolId'
        __BaseStrategy_init(_poolId);

        // Initialize the RecipientsExtension
        __RecipientsExtension_init(_recipientExtensionInitializeData);

        superfluidHost = _sqfSuperfluidInitializeParams.superfluidHost;
        minPassportScore = _sqfSuperfluidInitializeParams.minPassportScore;
        recipientSuperAppFactory = IRecipientSuperAppFactory(_sqfSuperfluidInitializeParams.recipientSuperAppFactory);

        if (
            _sqfSuperfluidInitializeParams.superfluidHost == address(0)
                || _sqfSuperfluidInitializeParams.allocationSuperToken == address(0)
                || _sqfSuperfluidInitializeParams.superfluidHost == address(0)
                || _sqfSuperfluidInitializeParams.passportDecoder == address(0)
        ) revert ZERO_ADDRESS();

        if (_sqfSuperfluidInitializeParams.initialSuperAppBalance == 0) revert INVALID();

        // validate the timestamps for this strategy
        if (_sqfSuperfluidInitializeParams.allocationStartTime > _sqfSuperfluidInitializeParams.allocationEndTime) {
            revert INVALID_TIMESTAMPS();
        }

        allocationSuperToken = ISuperToken(_sqfSuperfluidInitializeParams.allocationSuperToken);
        poolSuperToken = ISuperToken(allo.getPool(_poolId).token);
        allocationSuperToken.getUnderlyingToken();

        initialSuperAppBalance = _sqfSuperfluidInitializeParams.initialSuperAppBalance;

        passportDecoder = IGitcoinPassportDecoder(_sqfSuperfluidInitializeParams.passportDecoder);
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

        // Set the new values
        allocationStartTime = _sqfSuperfluidInitializeParams.allocationStartTime;
        allocationEndTime = _sqfSuperfluidInitializeParams.allocationEndTime;

        emit AllocationTimestampsUpdated(
            _sqfSuperfluidInitializeParams.allocationStartTime,
            _sqfSuperfluidInitializeParams.allocationEndTime,
            msg.sender
        );
    }

    /// ====================================
    /// ============== Main ================
    /// ====================================

    // /// @notice Register Recipient to the pool
    // /// @dev The '_data' parameter is encoded as follows:
    // ///     - If useRegistryAnchor is true, then the data is encoded as (address recipientId, Metadata metadata)
    // ///     - If useRegistryAnchor is false, then the data is encoded as (address recipientAddress, address registryAnchor, Metadata metadata)
    // /// @param _data The data to be decoded
    // /// @param _sender The sender of the transaction
    // /// @return recipientId The ID of the recipient
    // function _registerRecipient(bytes memory _data, address _sender)
    //     internal
    //     virtual
    //     override
    //     onlyActiveRegistration
    //     returns (address recipientId)
    // {
    //     address recipientAddress;
    //     address registryAnchor;
    //     bool isUsingRegistryAnchor;

    //     Metadata memory metadata;

    //     // decode data custom to this strategy
    //     if (useRegistryAnchor) {
    //         (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

    //         // when registry gating is enabled, the recipientId must be a profile member
    //         if (!_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
    //     } else {
    //         (registryAnchor, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));
    //         isUsingRegistryAnchor = registryAnchor != address(0);
    //         recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

    //         // when using registry anchor, the ID of the recipient must be a profile member
    //         if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
    //     }

    //     // make sure that if metadata is required, it is provided
    //     if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
    //         revert INVALID_METADATA();
    //     }

    //     // make sure the recipient address is not the zero address
    //     if (recipientAddress == address(0)) revert RECIPIENT_ERROR(recipientId);

    //     Recipient storage recipient = recipients[recipientId];

    //     // update the recipients data
    //     recipient.recipientAddress = recipientAddress;
    //     recipient.metadata = metadata;
    //     recipient.useRegistryAnchor = useRegistryAnchor ? true : isUsingRegistryAnchor;

    //     Status currentStatus = recipient.recipientStatus;

    //     if (currentStatus == Status.None) {
    //         // recipient registering new application
    //         recipient.recipientStatus = Status.Pending;
    //         emit Registered(recipientId, _data, _sender);
    //     } else if (currentStatus == Status.Pending) {
    //         // emit the new status with the '_data' that was passed in
    //         emit UpdatedRegistration(recipientId, _data, _sender);
    //     } else {
    //         revert INVALID();
    //     }
    // }

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

        emit Distributed(address(0), _data);
    }

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(address[] memory, uint256[] memory, bytes memory _data, address _sender)
        internal
        override
        onlyActiveAllocation
    {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        (address recipientId, int96 flowRate) = abi.decode(_data, (address, int96));

        Recipient storage recipient = _recipients[recipientId];
        address superApp = recipientIdSuperApps[recipientId];

        if (Status(_getUintRecipientStatus(recipientId)) != Status.Accepted || superApp == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        (uint256 lastUpdated, int96 currentFlowRate,,) = allocationSuperToken.getFlowInfo(_sender, superApp);

        if (currentFlowRate == 0 || lastUpdated == 0) {
            // create the flow
            // enhancement: explore making a factory which would be approved by allocator only once
            allocationSuperToken.createFlowFrom(_sender, superApp, flowRate);
        } else {
            // update the flow
            allocationSuperToken.updateFlowFrom(_sender, superApp, flowRate);
        }

        emit Allocated(recipientId, _sender, uint256(int256(flowRate)), _data);
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
        // validate the timestamps for this strategy
        if (_allocationStartTime > _allocationEndTime) revert INVALID_TIMESTAMPS();

        // Set the new values
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit AllocationTimestampsUpdated(allocationStartTime, allocationEndTime, msg.sender);

        _updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
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
    function _isValidAllocator(address _allocator) internal view returns (bool) {
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
            Recipient storage recipient = _recipients[recipientId];

            // only pending applications can be updated
            // and the new status can only be Accepted or Rejected
            if (
                Status(_getUintRecipientStatus(recipientId)) != Status.Pending
                    || (recipientStatus != Status.Accepted && recipientStatus != Status.Rejected)
            ) {
                revert RECIPIENT_ERROR(recipientId);
            }
            _setRecipientStatus(recipientId, uint256(recipientStatus));

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            if (recipientStatus == Status.Accepted) {
                address superApp = recipientSuperAppFactory.createRecipientSuperApp(
                    recipient.recipientAddress, address(this), superfluidHost, allocationSuperToken, true, true, true
                );

                allocationSuperToken.transfer(address(superApp), initialSuperAppBalance);

                // Add recipientAddress as member of the GDA with 1 unit
                _updateMemberUnits(recipientId, recipient.recipientAddress, 1);

                recipientIdSuperApps[recipientId] = superApp;
                // superApps[address(superApp)] = recipientId;
                // recipient.superApp = superApp;
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
            Recipient storage recipient = _recipients[recipientId];

            // if the status is none or appealed then revert
            Status recipientStatus = Status(_getUintRecipientStatus(recipientId));
            if (recipientStatus == Status.None || recipientStatus == Status.Canceled) {
                revert RECIPIENT_ERROR(recipientId);
            }

            _setRecipientStatus(recipientId, uint256(Status.Canceled));

            // address recipientSuperApp = recipient.superApp;

            // Update mappings as recipient is cancelled
            // delete recipient.superApp;
            // delete superApps[address(recipientSuperApp)];
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
        address recipientId = superAppsRecipientIds[msg.sender];

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

        Recipient storage recipient = _recipients[recipientId];

        _updateMemberUnits(recipientId, recipient.recipientAddress, uint128(recipientTotalUnits));

        uint256 currentFlowRate = recipientFlowRate[recipientId];

        recipientFlowRate[recipientId] = currentFlowRate + _newFlowRate - _previousFlowRate;

        emit TotalUnitsUpdated(recipientId, recipientTotalUnits);
    }

    function _beforeWithdraw(address _token, uint256, address) internal override {
        if (_token == address(poolSuperToken)) {
            revert INVALID();
        }
    }

    /// @notice Close the stream
    function closeStream() external onlyPoolManager(msg.sender) {
        poolSuperToken.distributeFlow(address(this), gdaPool, 0, "0x");
        _transferAmount(address(poolSuperToken), msg.sender, poolSuperToken.balanceOf(address(this)));
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the recipientId of a super app
    /// @param _superApp The super app
    /// @return The recipientId
    function getRecipientIdOfSuperApp(address _superApp) external view returns (address) {
        return superAppsRecipientIds[_superApp];
    }

    /// @notice Get the super app of a recipient
    /// @param _recipientId The ID of the recipient
    /// @return The super app
    function getSuperAppOfRecipientId(address _recipientId) external view returns (address) {
        return recipientIdSuperApps[_recipientId];
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

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
