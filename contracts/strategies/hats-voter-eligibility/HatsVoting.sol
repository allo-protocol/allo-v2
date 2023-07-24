// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IHats} from "@hats-protocol/Interfaces/IHats.sol";

/*
Spec: "Optimistic Grants Committee"
- Must wear a given hat in order to allocate (vote) (Mimicking a grant committee)
- Hat wearers can allocate up to the remaining pool balance
- Recipient applies with the amount they'd like to receive
- A Hat wearer can approve (allocate) to the recipient that amount
- There is a delay period during which another Hat wearer can veto an allocation
- After the delay period, anyone can call distribute to transfer funds to the
recipient
*/

/// @title Hats Protocol Allocator Strategy
/// @author 0xZakk (zakk@gitcoin.co)
/// @notice An allocation strategy that uses Hats Protocol to determine who can allocate a pool of funding
contract HatsStrategy is BaseStrategy {
    /// @notice Recipient, a group or individual that applies to receive funding from the pool managed by this strategy
    struct Recipient {
        address recipientId;
        uint256 amount;
        Metadata metadata;
        RecipientStatus status;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Constant for Hats contract address
    IHats constant HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

    uint256 constant DELAY_LENGTH = 3 days;

    /// @notice ID of the Hat that must be worn to allocate from pools managed by this strategy
    uint256 public hatId;

    /// @notice Map an address for a recipient to the matching Recipient struct
    mapping(address => Recipient) public recipients;

    /// @notice Mapping for tracking when a recipient was approved
    mapping(address => uint256) public approvalTime;

    /// @notice Receipts for payouts
    mapping(address => PayoutSummary) public payoutSummaries;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Invoked when sender does not have authorization
    error UNAUTHORIZED();

    /// @notice Invoked when a recipient has already registered
    error RECIPIENT_ALREADY_REGISTERED();

    /// @notice Invoked when a recipient error occurs
    error RECIPIENT_ERROR(address recipientId);

    /// @notice Invoked when the delay period has not passed
    error DELAY_NOT_MET();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when someone registers to be a recipient
    event Registered(address indexed recipientId, Metadata metadata, uint256 amount);

    /// @notice Emitted when an allocation is approved to a recipient
    event Allocated(address indexed recipientId, uint256 amount, ERC20 token, address sender);

    /// @notice Emitted when a distribution is made
    event Distributed(address indexed recipientId, uint256 amount, address sender);

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// ===================================
    /// ========== Constructor ============
    /// ===================================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// @notice Initializes the strategy by setting the hatID and poolId
    /// @dev This should be called once and only by Allo.sol
    /// @param _poolId The ID of the pool managed by this strategy
    /// @param _data Arbitrary data passed through from pool creation
    function initialize(uint256 _poolId, bytes memory _data) external override {
        hatId = abi.decode(_data, (uint256));
        __BaseStrategy_init(_poolId);
    }

    /// ===============================
    /// ========== Methods ============
    /// ===============================

    /// @notice Method for registering a recipient from the pool
    /// @dev Should only be called by Allo.sol (set in BaseStrategy.sol)
    /// @param _data Bytes string that includes the recipientId, amount, and metadata for the recipient's application
    /// @param _sender Address for msg.sender, forwarded from Allo
    /// @return address The recipient address
    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address) {
        // Data: recipientId address, amount requested, metadata
        (address recipientId, uint256 amount, Metadata memory metadata) =
            abi.decode(_data, (address, uint256, Metadata));

        // Check that the recipientId is in the Registry
        if (!_isValidAnchor(recipientId)) revert UNAUTHORIZED();

        // Check that the sender is a member of the project
        if (!_isIdentityMember(recipientId, _sender)) revert UNAUTHORIZED();

        // Reject if already registered
        if (recipients[recipientId].status != RecipientStatus.None) {
            revert RECIPIENT_ALREADY_REGISTERED();
        }

        Recipient storage recipient = recipients[recipientId];

        recipient.recipientId = recipientId;
        recipient.amount = amount;
        recipient.metadata = metadata;
        recipient.status = RecipientStatus.Pending;

        emit Registered(recipientId, metadata, amount);

        return recipientId;
    }

    /// @notice Method for approving an allocation
    /// @dev Should only be called by Allo.sol
    /// @param _data Bytes string that holds the address for the recipient being approved (recipientId)
    /// @param _sender Sender of the transaction (msg.sender), forwarded from Allo
    function _allocate(bytes memory _data, address _sender) internal override {
        if (!HATS.isWearerOfHat(_sender, hatId)) revert UNAUTHORIZED();

        (address recipientId, bool approval) = abi.decode(_data, (address, bool));

        Recipient storage recipient = recipients[recipientId];

        if (approval) {
            if (recipient.status != RecipientStatus.Pending) revert UNAUTHORIZED();

            recipient.status = RecipientStatus.Accepted;
            approvalTime[recipientId] = block.timestamp;

            IAllo.Pool memory pool = allo.getPool(poolId);
            emit Allocated(recipientId, recipient.amount, pool.token, _sender);
        } else {
            if (recipient.status != RecipientStatus.Pending || recipient.status != RecipientStatus.Accepted) {
                revert UNAUTHORIZED();
            }

            recipient.status = RecipientStatus.Rejected;

            emit Rejected(recipient.recipientId);
        }
    }

    /// @notice Method for distributing funds from the pool to an approved recipient
    /// @dev Should only be called by Allo.sol
    /// @param _recipientIds List of addresses representing recipients
    /// @param _sender Sender of the transaction (msg.sender), forwarded from Allo
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender) internal override {
        uint256 recipientLength = _recipientIds.length;

        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];

            Recipient storage recipient = recipients[recipientId];

            if (recipient.status != RecipientStatus.Accepted) {
                revert RECIPIENT_ERROR(recipientId);
            }

            if (block.timestamp < approvalTime[recipientId] + DELAY_LENGTH) {
                revert DELAY_NOT_MET();
            }

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientId, recipient.amount);

            emit Distributed(recipient.recipientId, recipient.amount, _sender);

            unchecked {
                i++;
            }
        }
    }

    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {
        uint256 recipientLength = _recipientIds.length;

        payouts = new PayoutSummary[](recipientLength);

        for (uint256 i = 0; i < recipientLength;) {
            payouts[i] = payoutSummaries[_recipientIds[i]];
            unchecked {
                i++;
            }
        }
    }

    function isValidAllocator(address _allocator) external view override returns (bool) {
        return HATS.isWearerOfHat(_allocator, hatId);
    }

    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return recipients[_recipientId].status;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Check if an anchor address is valid
    /// @param _anchor Anchor address to check
    /// @return bool True if anchor is valid
    function _isValidAnchor(address _anchor) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        return registry.getIdentityByAnchor(_anchor).id != 0;
    }

    /// @notice Check if sender is identity owner or member
    /// @param _anchor Anchor of the identity
    /// @param _sender The sender of the transaction
    function _isIdentityMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isOwnerOrMemberOfIdentity(identity.id, _sender);
    }
}
