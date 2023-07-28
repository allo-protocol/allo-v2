// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "@openzeppelin/governance/utils/IVotes.sol";
// Core Contracts
import {QVSimpleStrategy} from "../qv-simple/QVSimpleStrategy.sol";

contract QVGovernanceERC20Votes is QVSimpleStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    IVotes public govToken;
    uint256 public timestamp;
    uint256 public reviewThreshold;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================
    constructor(address _allo, string memory _name) QVSimpleStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public override {
        (
            address _govToken,
            uint256 _timestamp,
            uint256 _reviewThreshold,
            bool _registryGating,
            bool _metadataRequired,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (address, uint256, uint256, bool, bool, uint256, uint256, uint256, uint256));
        __QVGovernanceERC20Votes_init(
            _govToken,
            _timestamp,
            _reviewThreshold,
            _poolId,
            _registryGating,
            _metadataRequired,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
    }

    function __QVGovernanceERC20Votes_init(
        address _govToken,
        uint256 _timestamp,
        uint256 _reviewThreshold,
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __QVSimpleStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            0,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
        govToken = IVotes(_govToken);
        timestamp = _timestamp;
        reviewThreshold = _reviewThreshold;

        // todo: test if it actually works
        // sanity check if token implements getPastVotes
        // should revert if function is not available
        govToken.getPastVotes(address(this), 0);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Review recipient application
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, InternalRecipientStatus[] calldata _recipientStatuses)
        external
        override
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < recipientLength;) {
            InternalRecipientStatus recipientStatus = _recipientStatuses[i];
            address recipientId = _recipientIds[i];
            if (recipientStatus == InternalRecipientStatus.None || recipientStatus == InternalRecipientStatus.Appealed)
            {
                revert RECIPIENT_ERROR(recipientId);
            }

            reviewsByStatus[recipientId][recipientStatus]++;

            if (reviewsByStatus[recipientId][recipientStatus] >= reviewThreshold) {
                Recipient storage recipient = recipients[recipientId];
                recipient.recipientStatus = recipientStatus;

                emit RecipientStatusUpdated(recipientId, recipientStatus, address(0));
            }

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view override returns (bool) {
        return govToken.getPastVotes(_allocator, timestamp) > 0;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        uint256 votePower = govToken.getPastVotes(_sender, timestamp);

        // check the voiceCreditsToAllocate is > 0
        if (voiceCreditsToAllocate == 0 || votePower == 0) {
            revert INVALID();
        }

        // check the time periods for allocation
        if (block.timestamp < allocationStartTime || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (voiceCreditsToAllocate + allocator.voiceCredits > votePower) {
            revert INVALID();
        }

        uint256 creditsCastToRecipient = allocator.voiceCreditsCastToRecipient[recipientId];
        uint256 votesCastToRecipient = allocator.votesCastToRecipient[recipientId];

        uint256 totalCredits = voiceCreditsToAllocate + creditsCastToRecipient;
        uint256 voteResult = _calculateVotes(totalCredits * 1e18);
        voteResult -= votesCastToRecipient;
        totalRecipientVotes += voteResult;
        recipient.totalVotesReceived += voteResult;

        allocator.voiceCreditsCastToRecipient[recipientId] += totalCredits;
        allocator.votesCastToRecipient[recipientId] += voteResult;

        emit Allocated(recipientId, voteResult, address(govToken), _sender);
    }
}
