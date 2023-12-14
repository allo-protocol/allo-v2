// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Accounts} from "./Accounts.sol";

/// @title RegistrySetup
/// @notice This contract is used to setup an empty Registry contract for testing purposes.
contract RegistrySetup is Test, Accounts {
    Registry internal _registry_;

    function __RegistrySetup() internal {
        _registry_ = new Registry();
        _registry_.initialize(registry_owner());
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

    bytes32 internal _profile1Id_;
    address internal _profile1Anchor_;

    bytes32 internal _profile2Id_;
    address internal _profile2Anchor_;

    function __RegistrySetupFull() internal {
        __RegistrySetup();
        _createProfiles();
    }

    function _createProfiles() internal {
        vm.prank(pool_admin());
        _poolProfileId_ = _registry_.createProfile(
            0, "Pool Profile 1", Metadata({protocol: 1, pointer: "PoolProfile1"}), pool_admin(), pool_managers()
        );
        _poolProfileAnchor_ = _registry_.getProfileById(_poolProfileId_).anchor;

        vm.prank(profile1_owner());
        _profile1Id_ = _registry_.createProfile(
            0, "Profile 1", Metadata({protocol: 1, pointer: "Profile1"}), profile1_owner(), profile1_members()
        );
        _profile1Anchor_ = _registry_.getProfileById(_profile1Id_).anchor;

        vm.prank(profile2_owner());
        _profile2Id_ = _registry_.createProfile(
            0, "Profile 2", Metadata({protocol: 1, pointer: "Profile2"}), profile2_owner(), profile2_members()
        );
        _profile2Anchor_ = _registry_.getProfileById(_profile2Id_).anchor;
    }

    function poolProfile_id() public view virtual returns (bytes32) {
        return _poolProfileId_;
    }

    function poolProfile_anchor() public view virtual returns (address) {
        return _poolProfileAnchor_;
    }

    function profile1_id() public view virtual returns (bytes32) {
        return _profile1Id_;
    }

    // Use ths anchor with Accounts.profile1_member1 or Accounts.profile1_member2
    function profile1_anchor() public view virtual returns (address) {
        return _profile1Anchor_;
    }

    function profile2_id() public view virtual returns (bytes32) {
        return _profile2Id_;
    }

    // Use ths anchor with Accounts.profile2_member1 or Accounts.profile2_member2
    function profile2_anchor() public view virtual returns (address) {
        return _profile2Anchor_;
    }
}

contract RegistrySetupFullLive is RegistrySetupFull {
    function __RegistrySetupFullLive() internal {
        _registry_ = Registry(0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3);
        _createProfiles();
    }
}
