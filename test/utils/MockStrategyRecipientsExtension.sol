// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {CoreBaseStrategy} from "../../contracts/strategies/CoreBaseStrategy.sol";
import {RecipientsExtension} from "../../contracts/extensions/contracts/RecipientsExtension.sol";

contract MockStrategyRecipientsExtension is CoreBaseStrategy, RecipientsExtension {
    constructor(address _allo) CoreBaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        RecipientInitializeData memory _initializeData = abi.decode(_data, (RecipientInitializeData));
        __RecipientsExtension_init(_initializeData);
    }

    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {}

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {}
}
