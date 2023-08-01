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
    bytes32 internal _poolProfileId_;
    address internal _poolProfileAnchor_;

    bytes32 internal _identity1Id_;
    address internal _identity1Anchor_;

    bytes32 internal _identity2Id_;
    address internal _identity2Anchor_;

    function __RegistrySetupFull() internal {
        __RegistrySetup();

        vm.prank(pool_admin());
        _poolProfileId_ = _registry_.createProfile(
            0, "Pool Profile 1", Metadata({protocol: 1, pointer: "PoolProfile1"}), pool_admin(), pool_managers()
        );
        _poolProfileAnchor_ = _registry_.getProfileById(_poolProfileId_).anchor;

        vm.prank(identity1_owner());
        _identity1Id_ = _registry_.createProfile(
            0, "Profile 1", Metadata({protocol: 1, pointer: "Profile1"}), identity1_owner(), identity1_members()
        );
        _identity1Anchor_ = _registry_.getProfileById(_identity1Id_).anchor;

        vm.prank(identity2_owner());
        _identity2Id_ = _registry_.createProfile(
            0, "Profile 2", Metadata({protocol: 1, pointer: "Profile2"}), identity2_owner(), identity2_members()
        );
        _identity2Anchor_ = _registry_.getProfileById(_identity2Id_).anchor;
    }

    function poolProfile_id() public view returns (bytes32) {
        return _poolProfileId_;
    }

    function poolProfile_anchor() public view returns (address) {
        return _poolProfileAnchor_;
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
