// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Allo} from "contracts/core/Allo.sol";
import {IBaseStrategy} from "contracts/strategies/IBaseStrategy.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

/// @dev This mock allows smock to override the functions of Allo contract
contract MockAllo is Allo {
    constructor() Allo() {}

    function _initializeOwner(address newOwner) internal virtual override {
        super._initializeOwner(newOwner);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual override {
        super._setRoleAdmin(role, adminRole);
    }

    function _checkOnlyPoolManager(uint256 _poolId, address _address) internal view virtual override {
        super._checkOnlyPoolManager(_poolId, _address);
    }

    function _checkOnlyPoolAdmin(uint256 _poolId, address _address) internal view virtual override {
        super._checkOnlyPoolAdmin(_poolId, _address);
    }

    function _createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal virtual override returns (uint256 poolId) {
        return super._createPool(
            _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );
    }

    function _allocate(
        uint256 _poolId,
        address[] memory _recipients,
        uint256[] memory _amounts,
        bytes memory __data,
        uint256 _value,
        address _allocator
    ) internal virtual override {
        super._allocate(_poolId, _recipients, _amounts, __data, _value, _allocator);
    }

    function _fundPool(uint256 _amount, address _funder, uint256 _poolId, IBaseStrategy _strategy)
        internal
        virtual
        override
    {
        super._fundPool(_amount, _funder, _poolId, _strategy);
    }

    function _isPoolAdmin(uint256 _poolId, address _address) internal view virtual override returns (bool) {
        return super._isPoolAdmin(_poolId, _address);
    }

    function _isPoolManager(uint256 _poolId, address _address) internal view virtual override returns (bool) {
        return super._isPoolManager(_poolId, _address);
    }

    function _updateRegistry(address _registry) internal virtual override {
        super._updateRegistry(_registry);
    }

    function _updateTreasury(address payable _treasury) internal virtual override {
        super._updateTreasury(_treasury);
    }

    function _updatePercentFee(uint256 _percentFee) internal virtual override {
        super._updatePercentFee(_percentFee);
    }

    function _updateBaseFee(uint256 _baseFee) internal virtual override {
        super._updateBaseFee(_baseFee);
    }

    function _updateTrustedForwarder(address __trustedForwarder) internal virtual override {
        super._updateTrustedForwarder(__trustedForwarder);
    }

    function _addPoolManager(uint256 _poolId, address _manager) internal virtual override {
        super._addPoolManager(_poolId, _manager);
    }

    function _msgSender() internal view virtual override returns (address) {
        return super._msgSender();
    }

    function setPool(uint256 _poolId, IAllo.Pool memory _pool) public {
        _pools[_poolId] = _pool;
    }

    function getNonce(address _caller) public view returns (uint256) {
        return _nonces[_caller];
    }
}
