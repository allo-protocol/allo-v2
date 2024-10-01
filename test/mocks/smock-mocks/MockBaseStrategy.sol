// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract MockBaseStrategy is BaseStrategy {
    constructor(address _allo) BaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory) external override {
        __BaseStrategy_init(_poolId);
    }

    function __BaseStrategy_init(uint256 _poolId) internal virtual override {
        super.__BaseStrategy_init(_poolId);
    }

    function _checkOnlyAllo() internal view virtual override {
        super._checkOnlyAllo();
    }

    function _checkOnlyPoolManager(address _sender) internal view virtual override {
        super._checkOnlyPoolManager(_sender);
    }

    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
        returns (address[] memory _recipientIds)
    {}

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

    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual override {}

    function _afterIncreasePoolAmount(uint256 _amount) internal virtual override {}

    function _beforeWithdraw(address _token, uint256 _amount, address _recipient) internal virtual override {}

    function _afterWithdraw(address _token, uint256 _amount, address _recipient) internal virtual override {}

    function _beforeRegisterRecipient(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _afterRegisterRecipient(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _beforeAllocate(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _afterAllocate(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _beforeDistribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function _afterDistribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {}

    function set__poolId(uint256 _poolId) external {
        poolId = _poolId;
    }

    function set__poolAmount(uint256 _poolAmount) external {
        poolAmount = _poolAmount;
    }
}
