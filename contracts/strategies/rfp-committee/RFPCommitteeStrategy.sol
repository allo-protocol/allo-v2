// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Core Contracts
import {RFPSimpleStrategy} from "../rfp-simple/RFPSimpleStrategy.sol";

contract RFPCommitteeStrategy is RFPSimpleStrategy {
    /// ===============================
    /// ========== Events =============
    /// ===============================
    event Voted(address indexed recipientId, address voter);

    /// ================================
    /// ========== Storage =============
    /// ================================

    uint256 public voteThreshold;
    // committee member address => recipient
    mapping(address => address) public votedFor;
    mapping(address => uint256) public votes;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) RFPSimpleStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        (uint256 _maxBid, bool _registryGating, bool _metadataRequired, uint256 _voteThreshold) =
            abi.decode(_data, (uint256, bool, bool, uint256));
        __RPFCommiteeStrategy_init(_poolId, _maxBid, _registryGating, _metadataRequired, _voteThreshold);
    }

    function __RPFCommiteeStrategy_init(
        uint256 _poolId,
        uint256 _maxBid,
        bool _registryGating,
        bool _metadataRequired,
        uint256 _voteThreshold
    ) internal {
        __RFPSimpleStrategy_init(_poolId, _maxBid, _registryGating, _metadataRequired);
        voteThreshold = _voteThreshold;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Select recipient for RFP allocation
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender) internal override onlyPoolManager(_sender) {
        if (acceptedRecipientId != address(0)) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        // check if the sender has already vote
        address voteCastedTo = votedFor[_sender];
        if (voteCastedTo != address(0)) {
            // remove the old vote
            votes[voteCastedTo] -= 1;
        }

        address recipientId = abi.decode(_data, (address));
        votes[recipientId] += 1;
        votedFor[_sender] = recipientId;
        emit Voted(recipientId, _sender);

        if (votes[recipientId] == voteThreshold) {
            acceptedRecipientId = recipientId;

            Recipient storage recipient = _recipients[acceptedRecipientId];
            recipient.recipientStatus = RecipientStatus.Accepted;
            _setPoolActive(false);

            emit Allocated(acceptedRecipientId, recipient.proposalBid, allo.getPool(poolId).token, address(0));
        }
    }
}
