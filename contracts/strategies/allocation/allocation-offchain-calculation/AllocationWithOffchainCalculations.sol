// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../BaseAllocationStrategy.sol";
import {Registry} from "../../../core/Registry.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {Transfer} from "../../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

/// @title AllocationWithOffchainCalculations
/// @notice A strategy that allows users to apply to a pool and vote on recipents
/// @dev This strategy is used for QF pools that have offchain calculations
/// @author allo-team
contract AllocationWithOffchainCalculations is BaseAllocationStrategy, Transfer, ReentrancyGuard {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error ALLOCATION_AMOUNT_UNDERFLOW();
    error ALLOCATION_AMOUNT_MISMATCH();
    error APPLICATIONS_NOT_OPEN();
    error IDENTITY_REQUIRED();
    error INVALID_TIME();
    error INVALID_INPUT();
    error VOTING_NOT_OPEN();
    error VOTING_NOT_ENDED();

    /// @notice Struct to hold details of an recipent
    struct Recipent {
        bytes32 identityId;
        address recipient;
        uint256 recipentId;
        mapping(address => uint256) tokenAmounts;
        Status status;
        Metadata metadata;
        address creator;
    }

    /// @notice Struct to hold details of an Allocation
    struct Allocation {
        uint256 recipentId;
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
        uint256 recipentId;
        address token;
    }

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    Registry public registry;

    uint256 public recipentStartTime;
    uint256 public recipentEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint256 private _index;

    bool public identityRequired;
    bool public payoutReady;

    /// @notice recipentId - Status
    mapping(uint256 => RecipentStatus) public recipentStatus;

    /// @notice recipentId -> Recipent
    mapping(uint256 => Recipent) public recipents;

    ///@notice recipentId -> PayoutSummary
    mapping(uint256 => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event RecipentSubmitted(
        uint256 indexed recipentId, bytes32 indexed identityId, address recipient, Metadata metadata, address sender
    );
    event RecipentStatusUpdated(address indexed applicant, uint256 indexed recipentId, Status status);
    event Allocated(bytes data, address indexed allocator);
    event Claimed(uint256 indexed recipentId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 recipentStartTime, uint256 recipentEndTime, uint256 votingStartTime, uint256 votingEndTime
    );

    /// @notice Initialize the contract
    /// @param _allo The address of the Allo contract
    /// @param _identityId The identityId of the pool
    /// @param _poolId The poolId of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public override {
        super.initialize(_allo, _identityId, _poolId, _data);

        // decode data custom to this strategy
        (bool _identityRequired, address _registry) = abi.decode(_data, (bool, address));
        identityRequired = _identityRequired;
        registry = Registry(_registry);
    }

    /// @notice Apply to the pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function registerRecipents(bytes memory _data, address _sender)
        external
        payable
        override
        onlyAllo
        returns (uint256)
    {
        if (recipentStartTime <= block.timestamp || recipentEndTime >= block.timestamp) {
            revert APPLICATIONS_NOT_OPEN();
        }

        (uint256 recipentId, address recipient, bytes32 _identityId, Metadata memory metadata) =
            abi.decode(_data, (uint256, address, bytes32, Metadata));

        if (identityRequired && !registry.isOwnerOrMemberOfIdentity(identityId, _sender)) {
            revert UNAUTHORIZED();
        }

        Recipent storage recipent;

        if (recipentId == 0) {
            // Create a new recipent
            recipentId = ++_index;

            recipent = recipents[recipentId];
            recipent.identityId = _identityId;
            recipent.recipentId = recipentId;
            recipent.recipient = recipient;
            recipent.status = Status.PENDING;
            recipent.metadata = metadata;
            recipent.creator = _sender;
        } else {
            // Update an existing recipent
            recipent = recipents[recipentId];

            if (identityRequired && !registry.isOwnerOrMemberOfIdentity(recipent.identityId, _sender)) {
                // if identityRequired is true, the indentity owner/member can update the recipent
                revert UNAUTHORIZED();
            } else if (recipent.creator != _sender) {
                // if identityRequired is false, only the creator of the recipent can update it
                revert UNAUTHORIZED();
            }

            // Update the recipent
            recipent.recipient = recipient;
            recipent.status = Status.REAPPLIED;
            recipent.metadata = metadata;
        }

        // Add the recipent to the recipents mapping
        recipentStatus[recipentId] = IAllocationStrategy.RecipentStatus.Pending;

        emit RecipentSubmitted(recipentId, identityId, recipient, metadata, _sender);

        return recipentId;
    }

    /// @notice Returns the status of the recipent
    /// @param _recipentId The recipentId of the recipent
    function getRecipentStatus(uint256 _recipentId) external view override returns (RecipentStatus) {
        return recipentStatus[_recipentId];
    }

    /// @notice Allocates votes to the recipent(s)
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

                Recipent storage recipent = recipents[allocations.data[j].recipentId];
                recipent.tokenAmounts[allocations.token] += amount;

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

    /// @notice Retrieves recipent payout amount
    /// @param _recipentId recipentId array of the recipents
    /// @return summaries PayoutSummary array of the recipents
    function getPayout(uint256[] memory _recipentId, bytes memory)
        external
        view
        returns (PayoutSummary[] memory summaries)
    {
        uint256 recipentIdLength = _recipentId.length;
        summaries = new PayoutSummary[](recipentIdLength);

        for (uint256 i = 0; i < recipentIdLength;) {
            summaries[i] = payoutSummaries[_recipentId[i]];
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ========= Custom Functions =========
    /// ====================================

    /// @notice Review recipents
    /// @param _data The data to be decoded
    /// @dev
    function reviewRecipents(bytes memory _data) external onlyPoolManager {
        (uint256[] memory recipentIds, Status[] memory statuses) = abi.decode(_data, (uint256[], Status[]));

        for (uint256 i; i < recipentIds.length;) {
            recipents[recipentIds[i]].status = statuses[i];
            // map to the Allo global status's
            recipentStatus[recipentIds[i]] = IAllocationStrategy.RecipentStatus.Accepted;

            emit RecipentStatusUpdated(msg.sender, recipentIds[i], statuses[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the payout amounts for all the recipents and marks the contract as ready for payout
    /// @param _data The data to be decoded
    /// @dev Pool admin can only set payout amounts for `ACCEPTED` recipents
    function setPayout(bytes memory _data) external onlyPoolManager {
        if (votingEndTime > block.timestamp) {
            revert VOTING_NOT_ENDED();
        }

        (uint256[] memory recipentIds, PayoutSummary[] memory payout) = abi.decode(_data, (uint256[], PayoutSummary[]));

        uint256 recipentIdsLength = recipentIds.length;
        if (recipentIdsLength != payout.length) {
            revert INVALID_INPUT();
        }

        for (uint256 i; i < recipentIdsLength;) {
            uint256 recipentId = recipentIds[i];

            if (recipents[recipentId].status != Status.ACCEPTED) {
                revert INVALID_INPUT();
            }

            payoutSummaries[recipentId] = payout[i];

            unchecked {
                i++;
            }
        }

        payoutReady = true;
    }

    /// @notice Claim the payout for the recipents
    /// @param _claims The claims to be processed
    function claim(Claim[] calldata _claims) external nonReentrant {
        if (votingEndTime > block.timestamp) {
            revert VOTING_NOT_ENDED();
        }

        uint256 recipentIdsLength = _claims.length;
        for (uint256 i; i < recipentIdsLength;) {
            Claim memory singleClaim = _claims[i];
            Recipent storage recipent = recipents[singleClaim.recipentId];
            uint256 amount = recipent.tokenAmounts[singleClaim.token];

            recipent.tokenAmounts[singleClaim.token] = 0;
            _transferAmount(singleClaim.token, recipent.recipient, amount);

            emit Claimed(singleClaim.recipentId, recipent.recipient, amount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the recipent & voting times
    /// @param _recipentStartTime The recipentStartTime of the pool
    /// @param _recipentEndTime The recipentEndTime of the pool
    /// @param _votingStartTime The votingStartTime of the pool
    /// @param _votingEndTime The votingEndTime of the pool
    function updateTimestamps(
        uint256 _recipentStartTime,
        uint256 _recipentEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external onlyPoolManager {
        if (
            _recipentStartTime > _recipentEndTime // recipentStartTime must be before recipentEndTime
                || _votingStartTime > _votingEndTime // votingStartTime must be before votingEndTime
                || _recipentStartTime < block.timestamp // recipentStartTime must be in the future
                || _votingStartTime < block.timestamp // votingStartTime must be in the future
        ) {
            revert INVALID_TIME();
        }

        recipentStartTime = _recipentStartTime;
        recipentEndTime = _recipentEndTime;
        votingStartTime = _votingStartTime;
        votingEndTime = _votingEndTime;

        emit TimestampsUpdated(_recipentStartTime, _recipentEndTime, _votingStartTime, _votingEndTime);
    }

    /// @notice Check if the pool is ready to payout
    /// @return bool True if the pool is ready to payout
    function readyToPayout(bytes calldata) external view returns (bool) {
        return payoutReady;
    }
}
