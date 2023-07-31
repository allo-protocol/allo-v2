// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {QVBaseStrategy} from "../qv-base/QVBaseStrategy.sol";

contract QVSimpleStrategy is QVBaseStrategy {
    event AllocatorAdded(address indexed allocator, address sender);
    event AllocatorRemoved(address indexed allocator, address sender);

    uint256 public maxVoiceCreditsPerAllocator;

    /// @notice allocator => bool
    mapping(address => bool) public allowedAllocators;

    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public virtual override onlyAllo {
        (
            bool _registryGating,
            bool _metadataRequired,
            uint256 _reviewThreshold,
            uint256 _maxVoiceCreditsPerAllocator,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, uint256, uint256));
        __QVBaseStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            _reviewThreshold,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );

        maxVoiceCreditsPerAllocator = _maxVoiceCreditsPerAllocator;
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view virtual override returns (bool) {
        return allowedAllocators[_allocator];
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Add allocator
    /// @param _allocator The allocator address
    function addAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = true;

        emit AllocatorAdded(_allocator, msg.sender);
    }

    /// @notice Remove allocator
    /// @param _allocator The allocator address
    function removeAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = false;

        emit AllocatorRemoved(_allocator, msg.sender);
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // check that the sender can allocate votes
        if (!allowedAllocators[_sender]) {
            revert UNAUTHORIZED();
        }

        if (!_isAcceptedRecipient(recipientId)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        if (voiceCreditsToAllocate + allocator.voiceCredits > maxVoiceCreditsPerAllocator) {
            revert INVALID();
        }

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
    }

    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == InternalRecipientStatus.Accepted;
    }
}
