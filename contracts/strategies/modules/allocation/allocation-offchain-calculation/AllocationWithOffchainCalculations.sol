// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../BaseAllocationStrategy.sol";
import {Registry} from "../../../core/Registry.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {Transfer} from "../../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

/// @title AllocationWithOffchainCalculations
/// @notice A strategy that allows users to apply to a pool and vote on recipients
/// @dev This strategy is used for QF pools that have offchain calculations
/// @author allo-team
contract AllocationWithOffchainCalculations is BaseAllocationStrategy, Transfer, ReentrancyGuard {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error ALLOCATION_AMOUNT_UNDERFLOW();
    error ALLOCATION_AMOUNT_MISMATCH();
    error REGISTRATION_NOT_OPEN();
    error IDENTITY_REQUIRED();
    error INVALID_TIME();
    error INVALID_INPUT();
    error VOTING_NOT_OPEN();
    error VOTING_NOT_ENDED();

    // Note: this is mapped to the Allo global status's in the mapping below.
    /// @notice Enum for the local status of the recipient
    enum Status {
        NONE,
        PENDING,
        ACCEPTED,
        REJECTED,
        REAPPLIED
    }

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bytes32 identityId;
        address payoutAddress;
        address recipientId;
        mapping(address => uint256) tokenAmounts;
        Status status;
        Metadata metadata;
        address creator;
    }

    /// @notice Struct to hold details of an Allocation
    struct Allocation {
        address recipientId;
        uint256 amount;
    }

    /// @notice Struct to hold details of an Allocations
    struct Allocations {
        address token;
        uint256 totalAmount;
        Allocation[] data;
    }

    /// @notice Struct to hold details of the allocations to claim
    struct Claim {
        address recipientId;
        address token;
    }

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    Registry public registry;

    uint256 public registerStartTime;
    uint256 public registerEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint160 private _index;

    bool public identityRequired;
    bool public payoutReady;

    /// @notice recipientId - Status
    mapping(address => RecipientStatus) public recipientStatus;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) public recipients;

    ///@notice recipientId -> PayoutSummary
    mapping(address => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event RecipientSubmitted(
        address indexed recipientId,
        bytes32 indexed identityId,
        address payoutAddress,
        Metadata metadata,
        address sender
    );
    event RecipientStatusUpdated(address indexed applicant, address indexed recipientId, Status status);
    event Allocated(bytes data, address indexed allocator);
    event Claimed(address indexed recipientId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 registerStartTime, uint256 registerEndTime, uint256 votingStartTime, uint256 votingEndTime
    );

    /// @notice Initialize the contract
    /// @param _allo The address of the Allo contract
    /// @param _identityId The identityId of the pool
    /// @param _poolId The poolId of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public override {
        __BaseAllocationStrategy_init("AllocationWithOffchainCalculationsV1", _allo, _identityId, _poolId, _data);

        // decode data custom to this strategy
        (bool _identityRequired, address _registry) = abi.decode(_data, (bool, address));
        identityRequired = _identityRequired;
        registry = Registry(_registry);
    }

    /// @notice Apply to the pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function registerRecipients(bytes memory _data, address _sender)
        external
        payable
        override
        onlyAllo
        returns (address)
    {
        if (registerStartTime <= block.timestamp || registerEndTime >= block.timestamp) {
            revert REGISTRATION_NOT_OPEN();
        }

        (address recipientId, address payoutAddress, bytes32 _identityId, Metadata memory metadata) =
            abi.decode(_data, (address, address, bytes32, Metadata));

        if (identityRequired && !registry.isOwnerOrMemberOfIdentity(identityId, _sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }

        Recipient storage recipient;

        if (recipientId == address(0)) {
            // Create a new recipient
            recipientId = address(++_index);

            recipient = recipients[recipientId];
            recipient.identityId = _identityId;
            recipient.recipientId = recipientId;
            recipient.payoutAddress = payoutAddress;
            recipient.status = Status.PENDING;
            recipient.metadata = metadata;
            recipient.creator = _sender;
        } else {
            // Update an existing recipient
            recipient = recipients[recipientId];

            if (identityRequired && !registry.isOwnerOrMemberOfIdentity(recipient.identityId, _sender)) {
                // if identityRequired is true, the indentity owner/member can update the recipient
                revert BaseStrategy_UNAUTHORIZED();
            } else if (recipient.creator != _sender) {
                // if identityRequired is false, only the creator of the recipient can update it
                revert BaseStrategy_UNAUTHORIZED();
            }

            // Update the recipient
            recipient.payoutAddress = payoutAddress;
            recipient.status = Status.REAPPLIED;
            recipient.metadata = metadata;
        }

        // Add the recipient to the recipients mapping
        recipientStatus[recipientId] = IAllocationStrategy.RecipientStatus.Pending;

        emit RecipientSubmitted(recipientId, identityId, payoutAddress, metadata, _sender);

        return recipientId;
    }

    /// @notice Returns the status of the recipient
    /// @param _recipientId The recipientId of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return recipientStatus[_recipientId];
    }

    /// @notice Allocates votes to the recipient(s)
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function allocate(bytes memory _data, address _sender) external payable override onlyAllo nonReentrant {
        if (votingStartTime > block.timestamp || votingEndTime < block.timestamp) {
            revert VOTING_NOT_OPEN();
        }

        // Decode the _data
        Allocations[] memory allocationsPerToken = abi.decode(_data, (Allocations[]));
        uint256 allocationsPerTokenLength = allocationsPerToken.length;
        for (uint256 i; i < allocationsPerTokenLength;) {
            // Get the allocations per token
            Allocations memory allocations = allocationsPerToken[i];

            uint256 allocationsTotalAmount = allocations.totalAmount;

            // convert to TransferData
            TransferData memory transferData =
                TransferData({from: _sender, to: address(this), amount: allocationsTotalAmount});

            // transfer total amount of token to this contract
            _transferAmountFrom(allocations.token, transferData);

            uint256 allocationDataLength = allocations.data.length;
            for (uint256 j = 0; j < allocationDataLength;) {
                uint256 amount = allocations.data[j].amount;
                allocationsTotalAmount -= amount;

                Recipient storage recipient = recipients[allocations.data[j].recipientId];
                recipient.tokenAmounts[allocations.token] += amount;

                unchecked {
                    j++;
                }
            }

            if (allocationsTotalAmount != 0) {
                revert ALLOCATION_AMOUNT_MISMATCH();
            }

            unchecked {
                i++;
            }
        }
        emit Allocated(_data, _sender);
    }

    /// @notice Retrieves recipient payout amount
    /// @param _recipientId recipientId array of the recipients
    /// @return summaries PayoutSummary array of the recipients
    function getRecipientPayouts(address[] memory _recipientId, bytes memory)
        external
        view
        returns (PayoutSummary[] memory summaries)
    {
        uint256 recipientIdLength = _recipientId.length;
        summaries = new PayoutSummary[](recipientIdLength);

        for (uint256 i = 0; i < recipientIdLength;) {
            summaries[i] = payoutSummaries[_recipientId[i]];
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ========= Custom Functions =========
    /// ====================================

    /// @notice Review recipients
    /// @param _data The data to be decoded
    /// @dev
    function reviewRecipients(bytes memory _data) external onlyPoolManager {
        (address[] memory recipientIds, Status[] memory statuses) = abi.decode(_data, (address[], Status[]));

        for (uint256 i; i < recipientIds.length;) {
            recipients[recipientIds[i]].status = statuses[i];
            // map to the Allo global status's
            recipientStatus[recipientIds[i]] = IAllocationStrategy.RecipientStatus.Accepted;

            emit RecipientStatusUpdated(msg.sender, recipientIds[i], statuses[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the payout amounts for all the recipients and marks the contract as ready for payout
    /// @param _data The data to be decoded
    /// @dev Pool admin can only set payout amounts for `ACCEPTED` recipients
    function setPayout(bytes memory _data) external onlyPoolManager {
        if (votingEndTime > block.timestamp) {
            revert VOTING_NOT_ENDED();
        }

        (address[] memory recipientIds, PayoutSummary[] memory payout) = abi.decode(_data, (address[], PayoutSummary[]));

        uint256 recipientIdsLength = recipientIds.length;
        if (recipientIdsLength != payout.length) {
            revert INVALID_INPUT();
        }

        for (uint256 i; i < recipientIdsLength;) {
            address recipientId = recipientIds[i];

            if (recipients[recipientId].status != Status.ACCEPTED) {
                revert INVALID_INPUT();
            }

            payoutSummaries[recipientId] = payout[i];

            unchecked {
                i++;
            }
        }

        payoutReady = true;
    }

    /// @notice Claim the payout for the recipients
    /// @param _claims The claims to be processed
    function claim(Claim[] calldata _claims) external nonReentrant {
        if (votingEndTime > block.timestamp) {
            revert VOTING_NOT_ENDED();
        }

        uint256 recipientIdsLength = _claims.length;
        for (uint256 i; i < recipientIdsLength;) {
            Claim memory singleClaim = _claims[i];
            Recipient storage recipient = recipients[singleClaim.recipientId];
            uint256 amount = recipient.tokenAmounts[singleClaim.token];

            recipient.tokenAmounts[singleClaim.token] = 0;
            _transferAmount(singleClaim.token, recipient.payoutAddress, amount);

            emit Claimed(singleClaim.recipientId, recipient.payoutAddress, amount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the recipient & voting times
    /// @param _registerStartTime The registerStartTime of the pool
    /// @param _registerEndTime The registerEndTime of the pool
    /// @param _votingStartTime The votingStartTime of the pool
    /// @param _votingEndTime The votingEndTime of the pool
    function updateTimestamps(
        uint256 _registerStartTime,
        uint256 _registerEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external onlyPoolManager {
        if (
            _registerStartTime > _registerEndTime // registerStartTime must be before registerEndTime
                || _votingStartTime > _votingEndTime // votingStartTime must be before votingEndTime
                || _registerStartTime < block.timestamp // registerStartTime must be in the future
                || _votingStartTime < block.timestamp // votingStartTime must be in the future
        ) {
            revert INVALID_TIME();
        }

        registerStartTime = _registerStartTime;
        registerEndTime = _registerEndTime;
        votingStartTime = _votingStartTime;
        votingEndTime = _votingEndTime;

        emit TimestampsUpdated(_registerStartTime, _registerEndTime, _votingStartTime, _votingEndTime);
    }

    /// @notice Check if the pool is ready to payout
    /// @return bool True if the pool is ready to payout
    function readyToPayout(bytes calldata) external view returns (bool) {
        return payoutReady;
    }
}
