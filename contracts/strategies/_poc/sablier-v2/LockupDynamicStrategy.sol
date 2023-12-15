// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISablierV2LockupDynamic} from "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import {Broker, LockupDynamic} from "@sablier/v2-core/src/types/DataTypes.sol";
import {IERC20 as SablierIERC20} from "@sablier/v2-core/src/types/Tokens.sol";

import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {BaseStrategy} from "../../BaseStrategy.sol";

contract LockupDynamicStrategy is BaseStrategy, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error ALLOCATION_EXCEEDS_POOL_AMOUNT();
    error STATUS_NOT_ACCEPTED();
    error STATUS_NOT_PENDING_OR_INREVIEW();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event BrokerSet(Broker broker);
    event RecipientStatusChanged(address recipientId, Status status);
    event RecipientSegmentsChanged(address recipientId, LockupDynamic.SegmentWithDelta[] segments);

    /// ================================
    /// ========== Storage =============
    /// ================================

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

    /// @notice Struct to hold details of a grant recipient
    struct Recipient {
        // slot 0
        bool useRegistryAnchor;
        bool cancelable;
        Status recipientStatus;
        address recipientAddress;
        // slot 1
        uint256 grantAmount;
        // slots [2..m]
        Metadata metadata;
        // slots [m..n]
        LockupDynamic.SegmentWithDelta[] segments;
    }

    struct InitializeParams {
        bool registryGating;
        bool metadataRequired;
        bool grantAmountRequired;
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
        (InitializeParams memory initializeParams) = abi.decode(_data, (InitializeParams));
        __LockupDynamicStrategy_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    function __LockupDynamicStrategy_init(uint256 _poolId, InitializeParams memory _initializeParams) internal {
        __BaseStrategy_init(_poolId);
        registryGating = _initializeParams.registryGating;
        metadataRequired = _initializeParams.metadataRequired;
        grantAmountRequired = _initializeParams.grantAmountRequired;
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient's stream ids
    /// @param _recipientId Id of the recipient
    function getAllRecipientStreamIds(address _recipientId) external view returns (uint256[] memory) {
        return _recipientStreamIds[_recipientId];
    }

    /// @notice Get the broker
    function getBroker() external view returns (Broker memory) {
        return broker;
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function getStatus(address _recipientId) external view returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory _recipientIds, bytes memory)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {
        uint256 recipientLength = _recipientIds.length;
        payouts = new PayoutSummary[](recipientLength);
        address recipientId;

        for (uint256 i; i < recipientLength;) {
            recipientId = _recipientIds[i];
            payouts[i] = _getPayout(recipientId, "");

            unchecked {
                i++;
            }
        }
    }

    /// @notice Get the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        Status status = _getRecipient(_recipientId).recipientStatus;
        if (status == Status.InReview) {
            return Status.Pending;
        } else {
            return Status(uint8(status));
        }
    }

    /// @notice Get the recipient's stream id at the given index
    /// @param _recipientId Id of the recipient
    /// @param streamIdIndex Index of the stream id
    function getRecipientStreamId(address _recipientId, uint256 streamIdIndex) external view returns (uint256) {
        return _recipientStreamIds[_recipientId][streamIdIndex];
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Cancel the stream and adjust the contract amounts.
    /// @param _recipientId Id of the recipient
    /// @param _streamId The id of the stream
    function cancelStream(address _recipientId, uint256 _streamId) external onlyPoolManager(msg.sender) {
        if (_recipients[_recipientId].recipientStatus != Status.Accepted) {
            revert STATUS_NOT_ACCEPTED();
        }

        _recipients[_recipientId].recipientStatus = Status.Canceled;

        uint128 refundedAmount = lockupDynamic.refundableAmountOf(_streamId);
        _recipients[_recipientId].grantAmount -= refundedAmount;
        allocatedGrantAmount -= refundedAmount;
        poolAmount += refundedAmount;
        lockupDynamic.cancel(_streamId);
    }

    /// @notice Change the recipient's segments
    /// @param _recipientId Id of the recipient
    /// @param _segments The new segments
    function changeRecipientSegments(address _recipientId, LockupDynamic.SegmentWithDelta[] calldata _segments)
        external
        onlyPoolManager(msg.sender)
    {
        if (
            _recipients[_recipientId].recipientStatus != Status.Pending
                && _recipients[_recipientId].recipientStatus != Status.InReview
        ) {
            revert STATUS_NOT_PENDING_OR_INREVIEW();
        }

        Recipient storage recipient = _recipients[_recipientId];
        delete recipient.segments;

        uint256 segmentCount = _segments.length;
        for (uint256 i; i < segmentCount; ++i) {
            recipient.segments.push(_segments[i]);
        }

        emit RecipientSegmentsChanged(_recipientId, _segments);
    }

    /// @notice Set the Sablier broker
    /// @param _broker The new Sablier broker to be set
    function setBroker(Broker memory _broker) external onlyPoolManager(msg.sender) {
        broker = _broker;
        emit BrokerSet(broker);
    }

    /// @notice Set the status of the recipient to InReview
    /// @param _recipientIds Ids of the recipients
    function setRecipientStatusToInReview(address[] calldata _recipientIds) external {
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

    /// @notice Withdraw funds from pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        poolAmount -= _amount;
        _transferAmount(allo.getPool(poolId).token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Check if address is valid allocator
    /// @param _allocator Address of the allocator
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

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
        LockupDynamic.SegmentWithDelta[] memory segments;
        bool useRegistryAnchor;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, cancelable, grantAmount, segments, metadata) =
                abi.decode(_data, (address, address, bool, uint256, LockupDynamic.SegmentWithDelta[], Metadata));

            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, useRegistryAnchor, cancelable, grantAmount, segments, metadata) =
                abi.decode(_data, (address, bool, bool, uint256, LockupDynamic.SegmentWithDelta[], Metadata));
            recipientId = _sender;
            if (useRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (grantAmountRequired && grantAmount == 0) {
            revert INVALID_REGISTRATION();
        }

        if (_recipients[recipientId].recipientStatus == Status.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        Recipient storage recipient = _recipients[recipientId];

        uint256 segmentCount = segments.length;
        for (uint256 i; i < segmentCount; ++i) {
            recipient.segments.push(segments[i]);
        }

        recipient.cancelable = cancelable;
        recipient.grantAmount = grantAmount;
        recipient.metadata = metadata;
        recipient.recipientAddress = recipientAddress;
        recipient.recipientStatus = Status.Pending;
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
        (address recipientId, Status recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, Status, uint256));

        Recipient storage recipient = _recipients[recipientId];

        if (
            recipient.recipientStatus != Status.Accepted // no need to accept twice
                && recipientStatus == Status.Accepted
        ) {
            IAllo.Pool memory pool = allo.getPool(poolId);
            allocatedGrantAmount += grantAmount;

            if (allocatedGrantAmount > poolAmount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }

            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = Status.Accepted;

            emit RecipientStatusChanged(recipientId, Status.Accepted);
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (
            recipient.recipientStatus != Status.Rejected // no need to reject twice
                && recipientStatus == Status.Rejected
        ) {
            recipient.recipientStatus = Status.Rejected;
            emit RecipientStatusChanged(recipientId, Status.Rejected);
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
        for (uint256 i; i < recipientLength;) {
            _distributeToLockupDynamic(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    function _distributeToLockupDynamic(address _recipientId, address _sender) private {
        Recipient memory recipient = _recipients[_recipientId];
        IAllo.Pool memory pool = allo.getPool(poolId);

        uint128 amount = uint128(recipient.grantAmount);

        LockupDynamic.CreateWithDeltas memory params = LockupDynamic.CreateWithDeltas({
            asset: SablierIERC20(pool.token),
            broker: broker,
            cancelable: recipient.cancelable,
            recipient: recipient.recipientAddress,
            segments: recipient.segments,
            sender: address(this),
            totalAmount: amount
        });

        poolAmount -= amount;
        IERC20(pool.token).forceApprove(address(lockupDynamic), amount);
        uint256 streamId = lockupDynamic.createWithDeltas(params);
        _recipientStreamIds[_recipientId].push(streamId);

        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }

    function _getPayout(address _recipientId, bytes memory)
        internal
        view
        virtual
        override
        returns (PayoutSummary memory)
    {
        Recipient memory recipient = _recipients[_recipientId];

        return PayoutSummary(recipient.recipientAddress, recipient.grantAmount);
    }

    /// @notice Check if sender is profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_anchor);
        return registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }
}
