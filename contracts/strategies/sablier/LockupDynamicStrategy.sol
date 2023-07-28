// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "@sablier/v2-core/types/Tokens.sol";
import {ISablierV2LockupDynamic} from "@sablier/v2-core/interfaces/ISablierV2LockupDynamic.sol";
import {Broker, LockupDynamic} from "@sablier/v2-core/types/DataTypes.sol";

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

contract LockupDynamicStrategy is BaseStrategy, ReentrancyGuard {
    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error RECIPIENT_ALREADY_ACCEPTED();
    error UNAUTHORIZED();
    error INVALID_REGISTRATION();
    error ALLOCATION_EXCEEDS_POOL_AMOUNT();
    error INVALID_METADATA();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event BrokerSet(Broker broker);
    event RecipientStatusChanged(address recipientId, InternalRecipientStatus status);

    /// ================================
    /// ========== Storage =============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        InReview
    }

    // slot 0
    bool public registryGating;
    bool public metadataRequired;
    bool public grantAmountRequired;
    ISablierV2LockupDynamic public lockupDynamic;
    // slot 1
    uint256 public allocatedGrantAmount;

    // slot 2 and 3
    /// @notice See https://docs.sablier.com/concepts/protocol/fees#broker-fees
    Broker public broker;

    // slots [3..n]
    mapping(address recipientId => Recipient recipient) private _recipients;
    mapping(address recipientId => uint256[] streamIds) private _recipientStreamIds;

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        // slot 0
        bool useRegistryAnchor;
        bool cancelable;
        InternalRecipientStatus recipientStatus;
        uint40 startTime;
        address recipientAddress;
        // slot 1
        uint256 grantAmount;
        // slots [2..m]
        Metadata metadata;
        // slots [m..n]
        LockupDynamic.Segment[] segments;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(ISablierV2LockupDynamic _lockupDynamic, address _allo, string memory _name)
        BaseStrategy(_allo, _name)
    {
        lockupDynamic = _lockupDynamic;
    }

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public virtual override {
        (bool _registryGating, bool _metadataRequired, bool _grantAmountRequired) =
            abi.decode(_data, (bool, bool, bool));
        __LockupDynamicStrategy_init(_poolId, _registryGating, _metadataRequired, _grantAmountRequired);
    }

    function __LockupDynamicStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        bool _grantAmountRequired
    ) internal {
        __BaseStrategy_init(_poolId);
        registryGating = _registryGating;
        metadataRequired = _metadataRequired;
        grantAmountRequired = _grantAmountRequired;
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @param _recipientId Id of the recipient
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = _getRecipient(_recipientId).recipientStatus;
        if (internalStatus == InternalRecipientStatus.InReview) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    function getRecipientStreamId(address _recipientId, uint256 streamIdIndex) external view returns (uint256) {
        return _recipientStreamIds[_recipientId][streamIdIndex];
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {
        uint256 recipientLength = _recipientIds.length;

        payouts = new PayoutSummary[](recipientLength);

        address recipientId;
        for (uint256 i = 0; i < recipientLength;) {
            recipientId = _recipientIds[i];
            payouts[i] = PayoutSummary(recipientId, _recipients[recipientId].grantAmount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if address is elgible allocator
    /// @param _allocator Address of the allocator
    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    function setBroker(Broker memory _broker) external onlyPoolManager(msg.sender) {
        broker = _broker;
        emit BrokerSet(broker);
    }

    /// @notice Set the internal status of the recipient to InReview
    /// @param _recipientIds Ids of the recipients
    function setIntenalRecipientStatusToInReview(address[] calldata _recipientIds) external {
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
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        poolAmount -= _amount;
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Register to the pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        returns (address recipientId)
    {
        bool cancelable;
        uint256 grantAmount;
        Metadata memory metadata;
        address recipientAddress;
        uint40 startTime;
        LockupDynamic.Segment[] memory segments;
        bool useRegistryAnchor;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, cancelable, grantAmount, startTime, segments, metadata) =
                abi.decode(_data, (address, address, bool, uint256, uint40, LockupDynamic.Segment[], Metadata));

            if (!_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, useRegistryAnchor, cancelable, grantAmount, startTime, segments, metadata) =
                abi.decode(_data, (address, bool, bool, uint256, uint40, LockupDynamic.Segment[], Metadata));
            recipientId = _sender;
            if (useRegistryAnchor && !_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (grantAmountRequired && grantAmount == 0) {
            revert INVALID_REGISTRATION();
        }

        if (_recipients[recipientId].recipientStatus == InternalRecipientStatus.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        Recipient storage recipient = _recipients[recipientId];

        uint256 segmentCount = segments.length;
        for (uint256 i = 0; i < segmentCount; ++i) {
            recipient.segments.push(segments[i]);
        }

        recipient.cancelable = cancelable;
        recipient.grantAmount = grantAmount;
        recipient.metadata = metadata;
        recipient.recipientAddress = recipientAddress;
        recipient.recipientStatus = InternalRecipientStatus.Pending;
        recipient.startTime = startTime;
        recipient.useRegistryAnchor = registryGating ? true : useRegistryAnchor;

        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Allocate amount to recipent for streaming grants
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyPoolManager(_sender)
    {
        (address recipientId, InternalRecipientStatus recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, InternalRecipientStatus, uint256));

        Recipient storage recipient = _recipients[recipientId];

        if (
            recipient.recipientStatus != InternalRecipientStatus.Accepted // no need to accept twice
                && recipientStatus == InternalRecipientStatus.Accepted
        ) {
            IAllo.Pool memory pool = allo.getPool(poolId);
            allocatedGrantAmount += grantAmount;

            if (allocatedGrantAmount > pool.amount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }

            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = InternalRecipientStatus.Accepted;

            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Accepted);
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (
            recipient.recipientStatus != InternalRecipientStatus.Rejected // no need to reject twice
                && recipientStatus == InternalRecipientStatus.Rejected
        ) {
            recipient.recipientStatus == InternalRecipientStatus.Rejected;
            emit RecipientStatusChanged(recipientId, InternalRecipientStatus.Rejected);
        }
    }

    /// @notice Distribute the upcoming milestone
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            _distributeLockupDynamic(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    function _distributeLockupDynamic(address _recipientId, address _sender) private {
        Recipient memory recipient = _recipients[_recipientId];
        IAllo.Pool memory pool = allo.getPool(poolId);

        uint128 amount = uint128(recipient.grantAmount);

        LockupDynamic.CreateWithMilestones memory params = LockupDynamic.CreateWithMilestones({
            asset: IERC20(pool.token),
            broker: broker,
            cancelable: recipient.cancelable,
            recipient: recipient.recipientAddress,
            segments: recipient.segments,
            sender: address(this),
            startTime: recipient.startTime,
            totalAmount: amount
        });

        poolAmount -= amount;
        IERC20(pool.token).approve(address(lockupDynamic), amount);
        uint256 streamId = lockupDynamic.createWithMilestones(params);
        _recipientStreamIds[_recipientId].push(streamId);

        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @notice Check if sender is identity owner or member
    /// @param _anchor Anchor of the identity
    /// @param _sender The sender of the transaction
    function _isIdentityMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isOwnerOrMemberOfIdentity(identity.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }
}