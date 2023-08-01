// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../shared/RegistrySetup.sol";

// Interfaces
import {IRegistry} from "../../../contracts/core/IRegistry.sol";
// Core Contracts
import {Registry} from "../../../contracts/core/Registry.sol";
// Internal libraries
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// Test libraries
import {TestUtilities} from "../../utils/TestUtilities.sol";
import {MockToken} from "../../utils/MockToken.sol";

contract RegistryTest is Test, RegistrySetup, Native {
    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);
    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);
    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);
    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    Metadata public metadata;
    string public name;
    uint256 public nonce;

    MockToken public token;

    function setUp() public {
        __RegistrySetup();
        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Profile";
        nonce = 2;

        token = new MockToken();
    }

    function test_createProfile() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testProfileId = TestUtilities._testUtilGenerateProfileId(nonce, address(this));
        address testAnchor = TestUtilities._testUtilGenerateAnchor(testProfileId, name, address(registry()));

        emit ProfileCreated(testProfileId, nonce, name, metadata, identity1_owner(), testAnchor);

        // create profile
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        // Check if the new profile was created
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        assertEq(testProfileId, newProfileId, "profileId");

        assertEq(profile.id, newProfileId, "newProfileId");
        assertEq(profile.name, name, "name");
        assertEq(profile.metadata.protocol, metadata.protocol, "metadata.protocol");
        assertEq(profile.metadata.pointer, metadata.pointer, "metadata.pointer");
        assertEq(registry().anchorToProfileId(profile.anchor), newProfileId, "anchorToProfileId");

        Registry.Profile memory identityByAnchor = registry().getProfileByAnchor(profile.anchor);
        assertEq(identityByAnchor.name, name, "getProfileByAnchor: name");
    }

    function testRevert_createProfile_owner_ZERO_ADDRESS() public {
        vm.expectRevert(IRegistry.ZERO_ADDRESS.selector);

        // create profile
        registry().createProfile(nonce, name, metadata, address(0), identity1_members());
    }

    function testRevert_createProfile_member_ZERO_ADDRESS() public {
        vm.expectRevert(IRegistry.ZERO_ADDRESS.selector);
        address[] memory _members = new address[](1);
        _members[0] = address(0);
        // create profile
        registry().createProfile(nonce, name, metadata, identity1_owner(), _members);
    }

    function testRevert_createProfile_NONCE_NOT_AVAILABLE() public {
        // create profile
        registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.NONCE_NOT_AVAILABLE.selector);

        // create profile with same index and name
        registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());
    }

    function test_updateProfileName() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        string memory newName = "New Name";
        address testAnchor = TestUtilities._testUtilGenerateAnchor(newProfileId, newName, address(registry()));
        vm.expectEmit(true, false, false, true);
        emit ProfileNameUpdated(newProfileId, newName, testAnchor);
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        vm.prank(identity1_owner());
        address newAnchor = registry().updateProfileName(newProfileId, newName);

        assertEq(registry().getProfileById(newProfileId).name, newName, "name");
        // old and new anchor should be mapped to profileId
        assertEq(registry().anchorToProfileId(profile.anchor), bytes32(0), "old anchor");
        assertEq(registry().anchorToProfileId(newAnchor), newProfileId, "new anchor");
    }

    function testRevert_updateProfileNameForInvalidId() public {
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce, address(this));
        string memory newName = "New Name";

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        vm.prank(identity1_owner());
        registry().updateProfileName(invalidProfileId, newName);
    }

    function testRevert_updateProfileName_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(identity1_member1());
        registry().updateProfileName(newProfileId, newName);
    }

    function testRevert_updateProfileName_UNAUTHORIZED_bymember() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(identity1_member1());
        registry().updateProfileName(newProfileId, newName);
    }

    function test_updateProfileMetadata_byidentity1_owner() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectEmit(true, false, false, true);
        emit ProfileMetadataUpdated(newProfileId, newMetadata);

        vm.prank(identity1_owner());
        registry().updateProfileMetadata(newProfileId, newMetadata);

        Registry.Profile memory profile = registry().getProfileById(newProfileId);
        assertEq(profile.metadata.protocol, newMetadata.protocol, "metadata.protocol");
        assertEq(profile.metadata.pointer, newMetadata.pointer, "metadata.pointer");
    }

    function test_updateProfileMetadataForInvalidId() public {
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce, address(this));
        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.prank(identity1_owner());
        registry().updateProfileMetadata(invalidProfileId, newMetadata);
    }

    function testRevert_updateProfileMetadata_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        vm.prank(identity1_notAMember());
        registry().updateProfileMetadata(newProfileId, newMetadata);
    }

    function test_isOwnerOrMemberOfProfile() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isOwnerOrMemberOfProfile(newProfileId, identity1_owner()), "isOwner");
        assertTrue(registry().isOwnerOrMemberOfProfile(newProfileId, identity1_member1()), "ismember");
        assertFalse(registry().isOwnerOrMemberOfProfile(newProfileId, identity1_notAMember()), "notAMember");
    }

    function test_isOwnerOfProfile() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isOwnerOfProfile(newProfileId, identity1_owner()), "isOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, identity1_member1()), "notAnOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, identity1_notAMember()), "notAMember");
    }

    function test_isMemberOfProfile() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, identity1_member1()), "member");
        assertFalse(registry().isMemberOfProfile(newProfileId, identity1_notAMember()), "notAMember");
    }

    function test_addMembers() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        assertFalse(registry().isMemberOfProfile(newProfileId, identity1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, identity1_member2()), "member2 not added");

        vm.prank(identity1_owner());
        registry().addMembers(newProfileId, identity1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, identity1_member1()), "member1 added");
        assertTrue(registry().isMemberOfProfile(newProfileId, identity1_member2()), "member2 added");
    }

    function testRevert_addMembers_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().addMembers(newProfileId, identity1_members());
    }

    function testRevert_addMembers_INVALID_ID() public {
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.prank(identity1_owner());
        registry().addMembers(invalidProfileId, identity1_members());
    }

    function testRevert_addMembers_ZERO_ADDRESS() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.expectRevert(IRegistry.ZERO_ADDRESS.selector);

        address[] memory _members = new address[](1);
        _members[0] = address(0);

        vm.prank(identity1_owner());
        registry().addMembers(newProfileId, _members);
    }

    function test_removeMembers() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, identity1_member1()), "member1 added");
        assertTrue(registry().isMemberOfProfile(newProfileId, identity1_member2()), "member2 added");

        vm.prank(identity1_owner());
        registry().removeMembers(newProfileId, identity1_members());

        assertFalse(registry().isMemberOfProfile(newProfileId, identity1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, identity1_member2()), "member2 not added");
    }

    function testRevert_removeMembers_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().removeMembers(newProfileId, identity1_members());
    }

    function testRevert_removeMembers_INVALID_ID() public {
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.prank(identity1_owner());
        registry().removeMembers(invalidProfileId, identity1_members());
    }

    function test_removeMembers_NON_EXISTING_MEMBERS() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), identity1_members());
        assertFalse(registry().isMemberOfProfile(newProfileId, identity2_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, identity2_member2()), "member2 not added");
        vm.prank(identity1_owner());
        // Try to remove non-existing members
        registry().removeMembers(newProfileId, identity2_members());
    }

    function test_updateProfilePendingidentity1_owner() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.expectEmit(true, false, false, true);
        emit ProfilePendingOwnerUpdated(newProfileId, identity1_notAMember());

        vm.prank(identity1_owner());
        registry().updateProfilePendingOwner(newProfileId, identity1_notAMember());
        address pendingOwner = registry().identityIdToPendingOwner(newProfileId);

        assertEq(pendingOwner, identity1_notAMember(), "after: pendingOwner");
    }

    function testRevert_updateProfilePendingOwner_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().updateProfilePendingOwner(newProfileId, identity1_notAMember());
    }

    function test_acceptProfileOwnership() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_owner());
        registry().updateProfilePendingOwner(newProfileId, identity1_notAMember());

        assertTrue(registry().isOwnerOfProfile(newProfileId, identity1_owner()), "before: isOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, identity1_notAMember()), "before: notAnOwner");
        address pendingOwner = registry().identityIdToPendingOwner(newProfileId);
        assertEq(pendingOwner, identity1_notAMember(), "before: pendingOwner");

        vm.expectEmit(true, false, false, true);
        emit ProfileOwnerUpdated(newProfileId, identity1_notAMember());

        vm.prank(identity1_notAMember());
        registry().acceptProfileOwnership(newProfileId);

        assertFalse(registry().isOwnerOfProfile(newProfileId, identity1_owner()), "after: notAnOwner");
        assertTrue(registry().isOwnerOfProfile(newProfileId, identity1_notAMember()), "after: isOwner");
        assertEq(registry().identityIdToPendingOwner(newProfileId), address(0), "after: pendingOwner");
    }

    function testRevert_acceptProfileOwnership_NOT_PENDING_identity1_owner() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_owner());
        registry().updateProfilePendingOwner(newProfileId, identity1_notAMember());

        vm.prank(identity1_owner());
        vm.expectRevert(IRegistry.NOT_PENDING_OWNER.selector);
        registry().acceptProfileOwnership(newProfileId);
    }

    function testRevert_acceptProfileOwnership_INVALID_ID() public {
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.expectRevert(IRegistry.NOT_PENDING_OWNER.selector);
        vm.prank(identity1_notAMember());
        registry().acceptProfileOwnership(invalidProfileId);
    }

    function testRevert_recoverFunds_INVALID_TOKEN_ADDRESS() public {
        address nonExistentToken = address(0xAAA);
        address recipient = address(0xBBB);
        vm.expectRevert();
        vm.prank(registry_owner());
        registry().recoverFunds(nonExistentToken, recipient);
    }

    function testRevert_recoverFunds_ZERO_RECIPIENT() public {
        address nonExistentToken = address(0xAAA);
        vm.expectRevert(IRegistry.ZERO_ADDRESS.selector);
        vm.prank(registry_owner());
        registry().recoverFunds(nonExistentToken, address(0));
    }

    function test_recoverFunds() public {
        address user = makeAddr("recipient");

        vm.deal(address(registry()), 1e18);

        assertEq(address(registry()).balance, 1e18);
        assertEq(user.balance, 0);

        vm.prank(registry_owner());
        registry().recoverFunds(NATIVE, user);

        assertEq(address(registry()).balance, 0);
        assertNotEq(user.balance, 0);
    }

    function test_recoverFunds_ERC20() public {
        uint256 amount = 100;
        token.mint(address(registry()), amount);
        address recipient = address(0xBBB);

        vm.prank(registry_owner());
        registry().recoverFunds(address(token), recipient);
        assertEq(token.balanceOf(recipient), amount, "amount");
    }
}
