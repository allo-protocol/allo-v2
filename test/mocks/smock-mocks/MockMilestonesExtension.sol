// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {MilestonesExtension} from "strategies/extensions/milestones/MilestonesExtension.sol";
import {IMilestonesExtension} from "strategies/extensions/milestones/IMilestonesExtension.sol";
import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

/// @dev This mock allows smock to override the functions of MilestonesExtension abstract contract
contract MockMilestonesExtension is BaseStrategy, IMilestonesExtension, MilestonesExtension {
    address public acceptedRecipientId;

    constructor(address _allo) BaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        uint256 _maxBid = abi.decode(_data, (uint256));
        __MilestonesExtension_init(_maxBid);
    }

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _register(address[] memory __recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
        returns (address[] memory _recipientIds)
    {}

    function __MilestonesExtension_init(uint256 _maxBid) internal virtual override {
        super.__MilestonesExtension_init(_maxBid);
    }

    function _validateSubmitUpcomingMilestone(address _recipientId, address _sender) internal virtual override {
        super._validateSubmitUpcomingMilestone(_recipientId, _sender);
    }

    function _setProposalBid(address _bidderId, uint256 _proposalBid) internal virtual override {
        super._setProposalBid(_bidderId, _proposalBid);
    }

    function _increaseMaxBid(uint256 _maxBid) internal virtual override {
        super._increaseMaxBid(_maxBid);
    }

    function _isAcceptedRecipient(address _recipientId) internal view virtual override returns (bool) {
        return _recipientId == acceptedRecipientId;
    }

    function _validateSetMilestones(address _sender) internal virtual override {
        super._validateSetMilestones(_sender);
    }

    function _checkOnlyPoolManager(address _sender) internal view virtual override {
        super._checkOnlyPoolManager(_sender);
    }

    function _validateReviewMilestone(address _sender, MilestoneStatus _milestoneStatus) internal virtual override {
        super._validateReviewMilestone(_sender, _milestoneStatus);
    }

    function _getMilestonePayout(address _recipientId, uint256 _milestoneId)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return super._getMilestonePayout(_recipientId, _milestoneId);
    }

    function set__milestones(uint256 _index, Milestone memory _milestone) external {
        if (milestones.length == 0) {
            milestones.push(_milestone);
        } else {
            milestones[_index] = _milestone;
        }
    }

    function set__maxBid(uint256 _maxBid) external {
        maxBid = _maxBid;
    }

    function set__bid(address _recipientId, uint256 _proposalBid) external {
        bids[_recipientId] = _proposalBid;
    }

    function get__milestones() external view returns (Milestone[] memory) {
        return milestones;
    }
}
