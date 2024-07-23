// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {CoreBaseStrategy} from "../../contracts/strategies/CoreBaseStrategy.sol";
import {MilestonesExtension} from "../../contracts/extensions/contracts/MilestonesExtension.sol";
import {IMilestonesExtension} from "../../contracts/extensions/interfaces/IMilestonesExtension.sol";
import {Test} from "forge-std/Test.sol";

contract MockStrategyMilestonesExtension is CoreBaseStrategy, MilestonesExtension, Test {
    constructor(address _allo) CoreBaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        IMilestonesExtension.InitializeParams memory _initializeData = abi.decode(_data, (IMilestonesExtension.InitializeParams));
        __MilestonesExtension_init(_initializeData);
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

    function expose__MilestonesExtension_init(InitializeParams memory _initializeParams) external {
        __MilestonesExtension_init(_initializeParams);
    }

    function expose_validateSubmitUpcomingMilestone(address _sender) external {
        _validateSubmitUpcomingMilestone(_sender);
    }

    function expose_setProposalBid(address _bidderId, uint256 _proposalBid) external {
        _setProposalBid(_bidderId, _proposalBid);
    }
}