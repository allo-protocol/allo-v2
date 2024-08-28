// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {MilestonesExtension} from "strategies/extensions/milestones/MilestonesExtension.sol";
import {IMilestonesExtension} from "strategies/extensions/milestones/IMilestonesExtension.sol";
import {Test} from "forge-std/Test.sol";

contract MockStrategyMilestonesExtension is BaseStrategy, MilestonesExtension, Test {
    address public acceptedRecipientId;

    constructor(address _allo) BaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        uint256 _maxBid = abi.decode(_data, (uint256));
        __MilestonesExtension_init(_maxBid);
    }

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {}

    function _register(address[] memory __recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {}

    function expose__MilestonesExtension_init(uint256 _maxBid) external {
        __MilestonesExtension_init(_maxBid);
    }

    function expose_validateSubmitUpcomingMilestone(address _recipientId, address _sender) external {
        _validateSubmitUpcomingMilestone(_recipientId, _sender);
    }

    function expose_setProposalBid(address _bidderId, uint256 _proposalBid) external {
        _setProposalBid(_bidderId, _proposalBid);
    }

    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return _recipientId == acceptedRecipientId;
    }
}
