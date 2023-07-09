// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./BaseAllocationStrategy.sol";
import {Registry} from "../../core/Registry.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {Transfer} from "../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

/// @title AllocationWithVotingBase
/// @notice A strategy that allows users to apply to a pool and vote on applications
/// @dev This strategy is used for QF pools that have offchain calculations
/// @author allo-team
contract AllocationWithVotingBase is BaseAllocationStrategy, Transfer, ReentrancyGuard {
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

    /// @notice Struct to hold details of an application
    struct Application {
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

    uint256 public applicationStartTime;
    uint256 public applicationEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint256 private _index;

    bool public identityRequired;
    bool public payoutReady;

    /// @notice recipentId - Status
    mapping(uint256 => ApplicationStatus) public applicationStatus;

    /// @notice recipentId -> Application
    mapping(uint256 => Application) public applications;

    ///@notice recipentId -> PayoutSummary
    mapping(uint256 => PayoutSummary) public payoutSummaries;

    /// ======================
    /// ======= Events =======
    /// ======================

    event ApplicationSubmitted(
        uint256 indexed recipentId, bytes32 indexed identityId, address recipient, Metadata metadata, address sender
    );
    event ApplicationStatusUpdated(address indexed applicant, uint256 indexed recipentId, Status status);
    event Allocated(bytes data, address indexed allocator);
    event Claimed(uint256 indexed recipentId, address receipient, uint256 amount);
    event TimestampsUpdated(
        uint256 applicationStartTime, uint256 applicationEndTime, uint256 votingStartTime, uint256 votingEndTime
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
    function applyToPool(bytes memory _data, address _sender) external payable override onlyAllo returns (uint256) {
        if (applicationStartTime <= block.timestamp || applicationEndTime >= block.timestamp) {
            revert APPLICATIONS_NOT_OPEN();
        }

        (uint256 recipentId, address recipient, bytes32 _identityId, Metadata memory metadata) =
            abi.decode(_data, (uint256, address, bytes32, Metadata));

        if (identityRequired && !registry.isOwnerOrMemberOfIdentity(identityId, _sender)) {
            revert UNAUTHORIZED();
        }

        Application storage application;

        if (recipentId == 0) {
            // Create a new application
            recipentId = ++_index;

            application = applications[recipentId];
            application.identityId = _identityId;
            application.recipentId = recipentId;
            application.recipient = recipient;
            application.status = Status.PENDING;
            application.metadata = metadata;
            application.creator = _sender;
        } else {
            // Update an existing application
            application = applications[recipentId];

            if (identityRequired && !registry.isOwnerOrMemberOfIdentity(application.identityId, _sender)) {
                // if identityRequired is true, the indentity owner/member can update the application
                revert UNAUTHORIZED();
            } else if (application.creator != _sender) {
                // if identityRequired is false, only the creator of the application can update it
                revert UNAUTHORIZED();
            }

            // Update the application
            application.recipient = recipient;
            application.status = Status.REAPPLIED;
            application.metadata = metadata;
        }

        // Add the application to the applications mapping
        applicationStatus[recipentId] = IAllocationStrategy.ApplicationStatus.Pending;

        emit ApplicationSubmitted(recipentId, identityId, recipient, metadata, _sender);

        return recipentId;
    }

    /// @notice Returns the status of the application
    /// @param _recipentId The recipentId of the application
    function getApplicationStatus(uint256 _recipentId) external view override returns (ApplicationStatus) {
        return applicationStatus[_recipentId];
    }

    /// @notice Allocates votes to the application(s)
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

                Application storage application = applications[allocations.data[j].recipentId];
                application.tokenAmounts[allocations.token] += amount;

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

    /// @notice Retrieves application payout amount
    /// @param _recipentId recipentId array of the applications
    /// @return summaries PayoutSummary array of the applications
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

    /// @notice Review applications
    /// @param _data The data to be decoded
    /// @dev
    function reviewApplications(bytes memory _data) external onlyPoolManager {
        (uint256[] memory recipentIds, Status[] memory statuses) = abi.decode(_data, (uint256[], Status[]));

        for (uint256 i; i < recipentIds.length;) {
            applications[recipentIds[i]].status = statuses[i];
            // map to the Allo global status's
            applicationStatus[recipentIds[i]] = IAllocationStrategy.ApplicationStatus.Accepted;

            emit ApplicationStatusUpdated(msg.sender, recipentIds[i], statuses[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the payout amounts for all the applications and marks the contract as ready for payout
    /// @param _data The data to be decoded
    /// @dev Pool admin can only set payout amounts for `ACCEPTED` applications
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

            if (applications[recipentId].status != Status.ACCEPTED) {
                revert INVALID_INPUT();
            }

            payoutSummaries[recipentId] = payout[i];

            unchecked {
                i++;
            }
        }

        payoutReady = true;
    }

    /// @notice Claim the payout for the applications
    /// @param _claims The claims to be processed
    function claim(Claim[] calldata _claims) external nonReentrant {
        if (votingEndTime > block.timestamp) {
            revert VOTING_NOT_ENDED();
        }

        uint256 recipentIdsLength = _claims.length;
        for (uint256 i; i < recipentIdsLength;) {
            Claim memory singleClaim = _claims[i];
            Application storage application = applications[singleClaim.recipentId];
            uint256 amount = application.tokenAmounts[singleClaim.token];

            application.tokenAmounts[singleClaim.token] = 0;
            _transferAmount(singleClaim.token, application.recipient, amount);

            emit Claimed(singleClaim.recipentId, application.recipient, amount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the application & voting times
    /// @param _applicationStartTime The applicationStartTime of the pool
    /// @param _applicationEndTime The applicationEndTime of the pool
    /// @param _votingStartTime The votingStartTime of the pool
    /// @param _votingEndTime The votingEndTime of the pool
    function updateTimestamps(
        uint256 _applicationStartTime,
        uint256 _applicationEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external onlyPoolManager {
        if (
            _applicationStartTime > _applicationEndTime // applicationStartTime must be before applicationEndTime
                || _votingStartTime > _votingEndTime // votingStartTime must be before votingEndTime
                || _applicationStartTime < block.timestamp // applicationStartTime must be in the future
                || _votingStartTime < block.timestamp // votingStartTime must be in the future
        ) {
            revert INVALID_TIME();
        }

        applicationStartTime = _applicationStartTime;
        applicationEndTime = _applicationEndTime;
        votingStartTime = _votingStartTime;
        votingEndTime = _votingEndTime;

        emit TimestampsUpdated(_applicationStartTime, _applicationEndTime, _votingStartTime, _votingEndTime);
    }

    /// @notice Check if the pool is ready to payout
    /// @return bool True if the pool is ready to payout
    function readyToPayout(bytes calldata) external view returns (bool) {
        return payoutReady;
    }
}
