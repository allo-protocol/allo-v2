// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {MilestonesExtension} from "strategies/extensions/milestones/MilestonesExtension.sol";
import {BaseStrategy} from "strategies/BaseStrategy.sol";

/// @dev This mock allows smock to override the functions of MilestonesExtension abstract contract
contract MockMilestonesExtension is BaseStrategy, MilestonesExtension {
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

    function _isAcceptedRecipient(address _recipientId) internal view virtual override returns (bool) {
        return _recipientId == acceptedRecipientId;
    }
}
