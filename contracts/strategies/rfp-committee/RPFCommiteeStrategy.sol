// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {RFPSimpleStrategy} from "../rfp-simple/RFPSimpleStrategy.sol";

contract RFPCommiteeStrategy is RFPSimpleStrategy {
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
        super.initialize(_poolId, _data);

        (maxBid, voteThreshold, registryGating) = abi.decode(_data, (uint256, uint256, bool));

        emit MAX_BID_UPDATED(maxBid);
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

        address votedForOld = votedFor[_sender];
        if (votedForOld != address(0)) {
            votes[votedForOld] -= 1;
        }

        address recipientId = abi.decode(_data, (address));

        votes[recipientId] += 1;
        votedFor[_sender] = recipientId;
        emit Voted(recipientId, _sender);

        if (votes[recipientId] == voteThreshold) {
            acceptedRecipientId = recipientId;
            emit Allocated(
                acceptedRecipientId, _getRecipient(recipientId).proposalBid, allo.getPool(poolId).token, address(0)
            );
        }
    }
}
