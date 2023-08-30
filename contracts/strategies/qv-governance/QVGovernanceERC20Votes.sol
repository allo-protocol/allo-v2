// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
// Core Contracts
import {QVBaseStrategy} from "../qv-base/QVBaseStrategy.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣮⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡏⠘⣿⣿⣿⣷⡀          ⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠹⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠁⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡄⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣴⣿⣿⣿⡿⠋⠁⠀⠀⠀⠉⠻⣿⣿⣿⣿⡆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⠄⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⢀⢀⢀⢀⢀⢀⢀⢀⠈⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣧⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠟⠿⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡿⠁⠀          ⠀⠀⢿⣿⣿⣿⣧⠀ ⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⣀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠋⠋⠋⠋⠋⠛⠙⠋⠛⠙⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃            ⠀     ⠟⠿⠟⠿⠆⠀⠸⠿⠿⠻⠗⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠀⠙⠛⠿⢿⢿⡿⡿⡿⠟⠏⠃⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

contract QVGovernanceERC20Votes is QVBaseStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    IVotes public govToken;
    uint256 public timestamp;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================
    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) external override {
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
        govToken = IVotes(_govToken);
        timestamp = _timestamp;

        // sanity check if token implements getPastVotes
        // should revert if function is not available
        govToken.getPastVotes(address(this), 0);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
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

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        uint256 votePower = govToken.getPastVotes(_sender, timestamp);

        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate + allocator.voiceCredits, votePower)) {
            revert INVALID();
        }

        if (!_isAcceptedRecipient(recipientId)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
    }

    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == InternalRecipientStatus.Accepted;
    }

    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _votePower)
        internal
        pure
        override
        returns (bool)
    {
        return (_voiceCreditsToAllocate <= _votePower);
    }
}
