// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Registry} from "contracts/core/Registry.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";

contract MockRegistry is IRegistry, Registry {
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
    }

    function _checkRole(bytes32 role, address account) internal view virtual override {
        super._checkRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
    }

    function _generateProfileId(uint256 _nonce, address _owner) internal pure virtual override returns (bytes32) {
        return super._generateProfileId(_nonce, _owner);
    }

    function _generateAnchor(bytes32 _profileId, string memory _name)
        internal
        virtual
        override
        returns (address anchor)
    {
        return super._generateAnchor(_profileId, _name);
    }

    function _checkOnlyProfileOwner(bytes32 _profileId) internal view virtual override {
        super._checkOnlyProfileOwner(_profileId);
    }

    function _isOwnerOfProfile(bytes32 _profileId, address _owner) internal view virtual override returns (bool) {
        return super._isOwnerOfProfile(_profileId, _owner);
    }

    function _isMemberOfProfile(bytes32 _profileId, address _member) internal view virtual override returns (bool) {
        return super._isMemberOfProfile(_profileId, _member);
    }

    function set_profilesById(bytes32 _profileId, IRegistry.Profile memory _profile) external {
        profilesById[_profileId] = _profile;
    }
}
