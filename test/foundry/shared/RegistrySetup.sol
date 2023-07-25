// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Accounts} from "./Accounts.sol";

/// @title RegistrySetup
/// @notice This contract is used to setup an empty Registry contract for testing purposes.
contract RegistrySetup is Test, Accounts {
    Registry internal _registry_;

    function __RegistrySetup() internal {
        _registry_ = new Registry(registry_owner());
    }

    function registry() public view returns (Registry) {
        return _registry_;
    }
}

/// @title RegistrySetupFull
/// @notice This contract is used to setup a Registry contract with two identities for testing purposes.
contract RegistrySetupFull is RegistrySetup {
    bytes32 internal _alloIdentityId_;
    address internal _alloIdentityAnchor_;

    bytes32 internal _poolIdentityId_;
    address internal _poolIdentityAnchor_;

    bytes32 internal _identity1Id_;
    address internal _identity1Anchor_;

    bytes32 internal _identity2Id_;
    address internal _identity2Anchor_;

    function __RegistrySetupFull() internal {
        __RegistrySetup();

        vm.prank(allo_owner());
        _alloIdentityId_ = _registry_.createIdentity(
            0, "Allo Identity", Metadata({protocol: 1, pointer: "AlloIdentity"}), allo_owner(), pool_managers()
        );

        _alloIdentityAnchor_ = _registry_.getIdentityById(_alloIdentityId_).anchor;

        vm.prank(pool_admin());
        _poolIdentityId_ = _registry_.createIdentity(
            0, "Pool Identity 1", Metadata({protocol: 1, pointer: "PoolIdentity1"}), pool_admin(), pool_managers()
        );

        _poolIdentityAnchor_ = _registry_.getIdentityById(_poolIdentityId_).anchor;

        vm.prank(identity1_owner());
        _identity1Id_ = _registry_.createIdentity(
            0, "Identity 1", Metadata({protocol: 1, pointer: "Identity1"}), identity1_owner(), identity1_members()
        );
        _identity1Anchor_ = _registry_.getIdentityById(_identity1Id_).anchor;

        vm.prank(identity2_owner());
        _identity2Id_ = _registry_.createIdentity(
            0, "Identity 2", Metadata({protocol: 1, pointer: "Identity2"}), identity2_owner(), identity2_members()
        );
        _identity2Anchor_ = _registry_.getIdentityById(_identity2Id_).anchor;
    }

    function alloIdentity_id() public view returns (bytes32) {
        return _alloIdentityId_;
    }

    function poolIdentity_id() public view returns (bytes32) {
        return _poolIdentityId_;
    }

    function poolIdentity_anchor() public view returns (address) {
        return _poolIdentityAnchor_;
    }

    function identity1_id() public view returns (bytes32) {
        return _identity1Id_;
    }

    function identity1_anchor() public view returns (address) {
        return _identity1Anchor_;
    }

    function identity2_id() public view returns (bytes32) {
        return _identity2Id_;
    }

    function identity2_anchor() public view returns (address) {
        return _identity2Anchor_;
    }
}
