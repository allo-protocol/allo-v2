// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {BaseStrategy} from "./../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

/// @title Proportional Payout Strategy
/// @notice This strategy allows the allocator to allocate votes to recipients
/// @author allo-team
contract ProportionalPayoutStrategy is BaseStrategy {
    /// =====================
    /// ======= Events ======
    /// =====================

    event AllocationTimeSet(uint256 startTime, uint256 endTime);

    /// =====================
    /// ======= Errors ======
    /// =====================

    error RECIPIENT_ERROR(address recipientId);
    error UNAUTHORIZED();
    error MAX_REACHED();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error INVALID();

    /// ======================
    /// ====== Modifier ======
    /// ======================

    modifier onlyActiveAllocation() {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
        _;
    }

    /// ======================
    /// ======= Storage ======
    /// ======================

    struct Recipient {
        address recipientAddress;
        Metadata metadata;
        RecipientStatus recipientStatus;
        uint256 totalVotesReceived;
    }

    /// @notice recipientId => Recipient
    mapping(address => Recipient) public recipients;
    /// @notice nftId => has allocated
    mapping(uint256 => bool) public hasAllocated;
    /// @notice recipientId => paid out
    mapping(address => bool) public paidOut;

    ERC721 public nft;

    uint256 public maxRecipientsAllowed;
    uint256 public recipientsCounter;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;
    uint256 public totalAllocations;

    // ===================
    // === Constructor ===
    // ===================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external override onlyAllo {
        (address _nft, uint256 _maxRecipientsAllowed, uint256 _allocationStartTime, uint256 _allocationEndTime) =
            abi.decode(_data, (address, uint256, uint256, uint256));

        __ProtportionalPayoutStrategy_init(
            _poolId, ERC721(_nft), _allocationStartTime, _allocationEndTime, _maxRecipientsAllowed
        );
    }

    function __ProtportionalPayoutStrategy_init(
        uint256 _poolId,
        ERC721 _nft,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxRecipients
    ) internal {
        if (_startTime >= _endTime || _endTime < block.timestamp) {
            revert INVALID();
        }
        __BaseStrategy_init(_poolId);

        nft = ERC721(_nft);
        maxRecipientsAllowed = _maxRecipients;

        _setAllocationTime(_startTime, _endTime);
        _setPoolActive(true);
    }

    /// ==================
    /// ==== Views =======
    /// ==================

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

    // ==================
    // ==== External ====
    // ==================

    /// @notice Set the allocation start and end timestamps
    /// @param _allocationStartTime The allocation start timestamp
    /// @param _allocationEndTime The allocation end timestamp
    function setAllocationTime(uint256 _allocationStartTime, uint256 _allocationEndTime)
        external
        onlyPoolManager(msg.sender)
    {
        _setAllocationTime(_allocationStartTime, _allocationEndTime);
    }

    // ==================
    // ==== Internal ====
    // ==================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return nft.balanceOf(_allocator) > 0;
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the NFT holder can call this function
    function _allocate(bytes memory _data, address _sender) internal override onlyActiveAllocation {
        (address recipientId, uint256 nftId) = abi.decode(_data, (address, uint256));

        if (hasAllocated[nftId] || nft.ownerOf(nftId) != _sender) {
            revert UNAUTHORIZED();
        }

        hasAllocated[nftId] = true;

        Recipient storage recipient = recipients[recipientId];

        if (recipient.recipientStatus != RecipientStatus.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        recipient.totalVotesReceived++;
        totalAllocations++;

        emit Allocated(recipientId, 1, address(0), _sender);
    }

    /// @notice Distribute the tokens to the recipients
    /// @param _recipientIds The recipient ids
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        override
        onlyAfterAllocation
    {
        uint256 payoutLength = _recipientIds.length;
        for (uint256 i = 0; i < payoutLength;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            PayoutSummary memory payout = _getPayout(recipientId, "");
            uint256 amount = payout.amount;

            if (paidOut[recipientId] || recipient.recipientStatus != RecipientStatus.Accepted || amount == 0) {
                revert RECIPIENT_ERROR(recipientId);
            }

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            paidOut[recipientId] = true;

            emit Distributed(recipientId, recipient.recipientAddress, amount, _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Get the payout for a single recipient
    /// @param _recipientId The recipient id
    /// @return The payout as a PayoutSummary struct
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient storage recipient = recipients[_recipientId];

        uint256 totalVotesReceived = recipient.totalVotesReceived;
        uint256 amount = totalAllocations > 0 ? poolAmount * totalVotesReceived / totalAllocations : 0;

        return PayoutSummary(recipient.recipientAddress, amount);
    }

    /// @notice Submit application to pool
    /// @param _data The data to be decoded: address recipientId, address recipientAddress, RecipientStatus status, Metadata memory metadata
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyPoolManager(_sender)
        returns (address)
    {
        (address recipientId, address recipientAddress, RecipientStatus status, Metadata memory metadata) =
            abi.decode(_data, (address, address, RecipientStatus, Metadata));

        // validate decoded id and address
        if (recipientId == address(0) || recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        Recipient storage recipient = recipients[recipientId];

        if (recipient.recipientStatus != RecipientStatus.Accepted && status == RecipientStatus.Accepted) {
            // when a recipient is accepted, increment the counter
            recipientsCounter++;
        } else if (recipient.recipientStatus == RecipientStatus.Accepted && status == RecipientStatus.Rejected) {
            // when a recipient is rejected, increment the counter
            recipientsCounter--;
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }

        if (recipientsCounter > maxRecipientsAllowed) {
            revert MAX_REACHED();
        }

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.recipientStatus = status;

        emit Registered(recipientId, _data, _sender);

        return recipientId;
    }

    /// @notice Set the allocation start and end timestamps
    /// @param _allocationStartTime The allocation start timestamp
    /// @param _allocationEndTime The allocation end timestamp
    function _setAllocationTime(uint256 _allocationStartTime, uint256 _allocationEndTime) internal {
        // time stamps must be in future and end time after start time.
        if (_allocationStartTime < block.timestamp || _allocationEndTime < _allocationStartTime) {
            revert INVALID();
        }
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit AllocationTimeSet(_allocationStartTime, _allocationEndTime);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = recipients[_recipientId];
    }
}
