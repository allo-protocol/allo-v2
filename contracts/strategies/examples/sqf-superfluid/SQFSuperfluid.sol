// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Libraries
import {
    ISuperToken,
    ISuperfluidPool
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IGitcoinPassportDecoder} from "strategies/examples/sqf-superfluid/IGitcoinPassportDecoder.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {IRecipientSuperAppFactory} from "strategies/examples/sqf-superfluid/IRecipientSuperAppFactory.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Core Contracts
import {RecipientsExtension} from "strategies/extensions/register/RecipientsExtension.sol";
import {AllocationExtension} from "strategies/extensions/allocate/AllocationExtension.sol";
import {NFTGatingExtension} from "strategies/extensions/gating/NFTGatingExtension.sol";
import {BaseStrategy} from "strategies/BaseStrategy.sol";

// Internal Libraries
import {Transfer} from "contracts/core/libraries/Transfer.sol";

contract SQFSuperfluid is
    BaseStrategy,
    RecipientsExtension,
    AllocationExtension,
    NFTGatingExtension,
    ReentrancyGuard
{
    using SuperTokenV1Library for ISuperToken;
    using FixedPointMathLib for uint256;
    using Transfer for address;

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details needed for initializing strategy
    /// @param passportDecoder The Gitcoin Passport Decoder
    /// @param superfluidHost The host contract for the superfluid protocol
    /// @param allocationSuperToken The allocation super token
    /// @param recipientSuperAppFactory The recipient SuperApp factory
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param minPassportScore The minimum passport score required to be an allocator
    /// @param initialSuperAppBalance The initial balance for the super app
    /// @param erc721s An array containing the NFTs to check eligibility
    struct SQFSuperfluidInitializeParams {
        address passportDecoder;
        address superfluidHost;
        address allocationSuperToken;
        address recipientSuperAppFactory;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 minPassportScore;
        uint256 initialSuperAppBalance;
        address[] erc721s;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

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

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @dev The initial balance for the super app
    uint256 public initialSuperAppBalance;

    /// @dev Available at https://console.superfluid.finance/
    /// @notice The host contract for the superfluid protocol
    address public superfluidHost;

    /// @notice The allocation super token
    ISuperToken public allocationSuperToken;

    /// @notice The pool super token
    ISuperToken public poolSuperToken;

    /// @notice The recipient SuperApp factory
    IRecipientSuperAppFactory public recipientSuperAppFactory;

    /// @notice The GDA pool which streams pool tokens to recipients
    ISuperfluidPool public gdaPool;

    /// @notice The Gitcoin Passport Decoder
    IGitcoinPassportDecoder public passportDecoder;

    /// @notice The minimum passport score required to be an allocator
    uint256 public minPassportScore;

    /// @notice An array containing the NFTs to check eligibility
    address[] public erc721s;

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

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Micro Grants Strategy
    /// @param _allo The 'Allo' contract
    constructor(address _allo) RecipientsExtension(_allo, "SQFSuperfluid", true) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
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

        // Initialize the AllocationExtension
        __AllocationExtension_init(
            new address[](0),
            _sqfSuperfluidInitializeParams.allocationStartTime,
            _sqfSuperfluidInitializeParams.allocationEndTime,
            true
        );

        if (
            _sqfSuperfluidInitializeParams.superfluidHost == address(0)
                || _sqfSuperfluidInitializeParams.allocationSuperToken == address(0)
                || _sqfSuperfluidInitializeParams.superfluidHost == address(0)
                || _sqfSuperfluidInitializeParams.passportDecoder == address(0)
        ) revert ZERO_ADDRESS();

        if (_sqfSuperfluidInitializeParams.initialSuperAppBalance == 0) revert INVALID();

        superfluidHost = _sqfSuperfluidInitializeParams.superfluidHost;
        minPassportScore = _sqfSuperfluidInitializeParams.minPassportScore;
        recipientSuperAppFactory = IRecipientSuperAppFactory(_sqfSuperfluidInitializeParams.recipientSuperAppFactory);
        allocationSuperToken = ISuperToken(_sqfSuperfluidInitializeParams.allocationSuperToken);
        poolSuperToken = ISuperToken(_ALLO.getPool(_poolId).token);
        initialSuperAppBalance = _sqfSuperfluidInitializeParams.initialSuperAppBalance;
        passportDecoder = IGitcoinPassportDecoder(_sqfSuperfluidInitializeParams.passportDecoder);
        gdaPool = SuperTokenV1Library.createPool(
            poolSuperToken,
            address(this),
            PoolConfig(
                /// @dev if true, the pool members can transfer their owned units
                /// else, only the pool admin can manipulate the units for pool members
                false,
                /// @dev if true, anyone can execute distributions via the pool
                /// else, only the pool admin can execute distributions via the pool
                true
            )
        );
        erc721s = _sqfSuperfluidInitializeParams.erc721s;
    }

    /// ====================================
    /// ============= External =============
    /// ====================================

    /// @notice Update the min passport score
    /// @param _minPassportScore The new min passport score
    function updateMinPassportScore(uint256 _minPassportScore) external onlyPoolManager(msg.sender) {
        minPassportScore = _minPassportScore;

        emit MinPassportScoreUpdated(_minPassportScore, msg.sender);
    }

    /// @notice Cancel (remove) recipient(s) application(s)
    /// @dev You can remove multiple recipients at once or just one.
    /// @param _recipientIds Ids of the recipients
    function cancelRecipients(address[] calldata _recipientIds)
        external
        onlyPoolManager(msg.sender)
        onlyActiveAllocation
        nonReentrant
    {
        uint256 recipientLength = _recipientIds.length;

        for (uint256 i; i < recipientLength; ++i) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = _recipients[recipientId];

            // if the status is none or appealed then revert
            Status recipientStatus = Status(_getUintRecipientStatus(recipientId));
            if (recipientStatus == Status.None || recipientStatus == Status.Canceled) {
                revert RecipientsExtension_RecipientError(recipientId);
            }

            _setRecipientStatus(recipientId, uint256(Status.Canceled));

            // Update mappings as recipient is cancelled
            address superApp = recipientIdSuperApps[recipientId];
            delete superAppsRecipientIds[superApp];
            delete recipientIdSuperApps[recipientId];
            delete recipientFlowRate[recipientId];

            // Set recipient units to 0 to stop streaming from GDA
            _updateMemberUnits(recipientId, recipient.recipientAddress, 0);

            emit Canceled(recipientId, msg.sender);
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

    /// @notice Close the stream
    function closeStream() external onlyPoolManager(msg.sender) {
        poolSuperToken.distributeFlow(address(this), gdaPool, 0, "0x");
        address(poolSuperToken).transferAmount(msg.sender, poolSuperToken.balanceOf(address(this)));
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function isValidAllocator(address _allocator) external view returns (bool) {
        return _isValidAllocator(_allocator);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @dev prevent the pool token from being withdrawn
    /// @param _token The token address
    /// @param _amount The amount to withdraw
    /// @param _recipient The address to withdraw to
    function _beforeWithdraw(address _token, uint256 _amount, address _recipient) internal override {
        if (_token == address(poolSuperToken)) {
            revert INVALID();
        }
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        // Check if the allocator has a minimum passport score
        uint256 allocatorScore = passportDecoder.getScore(_allocator);
        if (allocatorScore < minPassportScore) {
            // If the allocator does not have the required score, then it is not valid. No need to check for NFTs
            return false;
        }

        // Check if the allocator has the required NFTs
        for (uint256 i; i < erc721s.length; i++) {
            _checkOnlyWithNFT(erc721s[i], _allocator);
        }
        // If didnt revert, then the allocator has the required NFT (and we assume it also has the required score)
        return true;
    }

    /// @dev If the recipient is accepted, create a super app for the recipient
    /// @param _newStatus The new status
    /// @param _oldStatus The old status
    /// @param _recipientIndex The index of the recipient
    /// @return _reviewedStatus The reviewed status
    function _reviewRecipientStatus(Status _newStatus, Status _oldStatus, uint256 _recipientIndex)
        internal
        override
        nonReentrant
        returns (Status _reviewedStatus)
    {
        if (_newStatus == Status.Accepted) {
            address recipientId = recipientIndexToRecipientId[_recipientIndex];
            address recipientAddress = _getRecipient(recipientId).recipientAddress;
            address superApp = recipientSuperAppFactory.createRecipientSuperApp(
                recipientAddress, address(this), superfluidHost, allocationSuperToken, true, true, true
            );

            // Add recipientAddress as member of the GDA with 1 unit
            _updateMemberUnits(recipientId, recipientAddress, 1);

            recipientIdSuperApps[recipientId] = superApp;
            superAppsRecipientIds[superApp] = recipientId;

            address(allocationSuperToken).transferAmount(address(superApp), initialSuperAppBalance);
        }

        _reviewedStatus = _newStatus;
    }

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientsAddresses NOT USED
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientsAddresses, bytes memory _data, address _sender)
        internal
        override
        onlyPoolManager(_sender)
    {
        _checkOnlyAfterRegistration();

        (int96 flowRate) = abi.decode(_data, (int96));
        poolSuperToken.distributeFlow(address(this), gdaPool, flowRate);

        emit Distributed(address(0), _data);
    }

    /// @notice This will allocate to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientsAddresses The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to each recipient
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(
        address[] memory _recipientsAddresses,
        uint256[] memory _amounts,
        bytes memory _data,
        address _sender
    ) internal override onlyActiveAllocation {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        int96[] memory flowRates = abi.decode(_data, (int96[]));

        for (uint256 i; i < _recipientsAddresses.length; i++) {
            address recipientId = _recipientsAddresses[i];
            address superApp = recipientIdSuperApps[recipientId];
            int96 flowRate = flowRates[i];

            if (Status(_getUintRecipientStatus(recipientId)) != Status.Accepted || superApp == address(0)) {
                revert RecipientsExtension_RecipientError(recipientId);
            }

            (uint256 lastUpdated, int96 currentFlowRate,,) = allocationSuperToken.getFlowInfo(_sender, superApp);

            if (currentFlowRate == 0 || lastUpdated == 0) {
                // create the flow
                // TODO: explore making a factory which would be approved by allocator only once
                allocationSuperToken.createFlowFrom(_sender, superApp, flowRate);
            } else {
                // update the flow
                allocationSuperToken.updateFlowFrom(_sender, superApp, flowRate);
            }

            emit Allocated(recipientId, _sender, uint256(int256(flowRate)), _data);
        }
    }

    /// @notice Check if the registration is active
    /// @dev Reverts if the registration is not active
    function _checkOnlyAfterRegistration() internal view {
        if (block.timestamp < registrationEndTime) {
            revert RecipientsExtension_RegistrationHasNotEnded();
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
