// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../shared/RegistrySetup.sol";

// Core Contracts
import {Registry} from "../../../contracts/core/Registry.sol";
import {Anchor} from "../../../contracts/core/Anchor.sol";

// Internal libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
// Test libraries
import {TestUtilities} from "../../utils/TestUtilities.sol";
import {MockERC20} from "../../utils/MockERC20.sol";

contract RegistryTest is Test, RegistrySetup, Native, Errors {
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

    MockERC20 public token;

    function setUp() public {
        __RegistrySetup();
        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Profile";
        nonce = 2;

        token = new MockERC20();
    }

    function test_initialize() public {
        Registry newRegistry = new Registry();
        newRegistry.initialize(registry_owner());

        assertTrue(newRegistry.hasRole(newRegistry.ALLO_OWNER(), registry_owner()));
    }

    function testRevert_initialize_zeroAddress() public {
        Registry newRegistry = new Registry();

        vm.expectRevert(ZERO_ADDRESS.selector);
        newRegistry.initialize(address(0));
    }

    function test_createProfile() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testProfileId = TestUtilities._testUtilGenerateProfileId(nonce, profile1_owner());
        address testAnchor = TestUtilities._testUtilGenerateAnchor(testProfileId, name, address(registry()));

        emit ProfileCreated(testProfileId, nonce, name, metadata, profile1_owner(), testAnchor);

        // create profile
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        // Check if the new profile was created
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        assertEq(testProfileId, newProfileId, "profileId");

        assertEq(profile.id, newProfileId, "newProfileId");
        assertEq(profile.name, name, "name");
        assertEq(profile.metadata.protocol, metadata.protocol, "metadata.protocol");
        assertEq(profile.metadata.pointer, metadata.pointer, "metadata.pointer");
        assertEq(registry().anchorToProfileId(profile.anchor), newProfileId, "anchorToProfileId");

        Registry.Profile memory profileByAnchor = registry().getProfileByAnchor(profile.anchor);
        assertEq(profileByAnchor.name, name, "getProfileByAnchor: name");
    }

    function test_createProfile_forAnotherOwner() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testProfileId = TestUtilities._testUtilGenerateProfileId(nonce, profile1_owner());
        address testAnchor = TestUtilities._testUtilGenerateAnchor(testProfileId, name, address(registry()));

        emit ProfileCreated(testProfileId, nonce, name, metadata, profile1_owner(), testAnchor);

        // create profile
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        // Check if the new profile was created
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        assertEq(testProfileId, newProfileId, "profileId");

        assertEq(profile.id, newProfileId, "newProfileId");
        assertEq(profile.name, name, "name");
        assertEq(profile.metadata.protocol, metadata.protocol, "metadata.protocol");
        assertEq(profile.metadata.pointer, metadata.pointer, "metadata.pointer");
        assertEq(registry().anchorToProfileId(profile.anchor), newProfileId, "anchorToProfileId");

        Registry.Profile memory profileByAnchor = registry().getProfileByAnchor(profile.anchor);
        assertEq(profileByAnchor.name, name, "getProfileByAnchor: name");
    }

    function testRevert_createProfile_owner_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);

        // create profile
        vm.prank(profile1_owner());
        registry().createProfile(nonce, name, metadata, address(0), profile1_members());
    }

    function testRevert_createProfile_member_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        address[] memory _members = new address[](1);
        _members[0] = address(0);
        // create profile
        vm.prank(profile1_owner());
        registry().createProfile(nonce, name, metadata, profile1_owner(), _members);
    }

    function testRevert_createProfile_UNAUTHORIZED_AddMemberWhenNotOwner() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        // create profile
        registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());
    }

    function testRevert_createProfile_NONCE_NOT_AVAILABLE() public {
        // create profile
        vm.prank(profile1_owner());
        registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        vm.expectRevert(NONCE_NOT_AVAILABLE.selector);

        // create profile with same index and name
        vm.prank(profile1_owner());
        registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());
    }

    function test_updateProfileName() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        string memory newName = "New Name";
        address testAnchor = TestUtilities._testUtilGenerateAnchor(newProfileId, newName, address(registry()));
        vm.expectEmit(true, false, false, true);
        emit ProfileNameUpdated(newProfileId, newName, testAnchor);
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        vm.prank(profile1_owner());
        address newAnchor = registry().updateProfileName(newProfileId, newName);

        assertEq(registry().getProfileById(newProfileId).name, newName, "name");
        // old and new anchor should be mapped to profileId
        assertEq(registry().anchorToProfileId(profile.anchor), bytes32(0), "old anchor");
        assertEq(registry().anchorToProfileId(newAnchor), newProfileId, "new anchor");
    }

    function testRevert_createProfile_existing_anchor_wrong_profile() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());
        // getAnchor
        Registry.Profile memory profile = registry().getProfileById(newProfileId);
        Anchor anchor = Anchor(payable(profile.anchor));

        bytes4 selector = bytes4(keccak256(bytes("profileId()")));
        vm.mockCall(address(anchor), abi.encodeWithSelector(selector), abi.encode(bytes32("hello world")));
        vm.expectRevert(ANCHOR_ERROR.selector);

        vm.prank(profile1_owner());
        registry().updateProfileName(newProfileId, name);
    }

    function test_updateProfileName_toTheNameBefore() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        string memory newName = "New Name";
        Registry.Profile memory profile = registry().getProfileById(newProfileId);

        address currentAnchor = profile.anchor;

        vm.startPrank(profile1_owner());

        address newAnchor = registry().updateProfileName(newProfileId, newName);
        assertNotEq(currentAnchor, newAnchor, "new anchor");

        address oldAnchor = registry().updateProfileName(newProfileId, name);
        assertEq(currentAnchor, oldAnchor, "old anchor");

        vm.stopPrank();
    }

    function testRevert_updateProfileNameForInvalidId() public {
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce, address(this));
        string memory newName = "New Name";

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(profile1_owner());
        registry().updateProfileName(invalidProfileId, newName);
    }

    function testRevert_updateProfileName_UNAUTHORIZED() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        vm.expectRevert(UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(profile1_member1());
        registry().updateProfileName(newProfileId, newName);
    }

    function testRevert_updateProfileName_UNAUTHORIZED_bymember() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        vm.expectRevert(UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(profile1_member1());
        registry().updateProfileName(newProfileId, newName);
    }

    function test_updateProfileMetadata_byprofile1_owner() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectEmit(true, false, false, true);
        emit ProfileMetadataUpdated(newProfileId, newMetadata);

        vm.prank(profile1_owner());
        registry().updateProfileMetadata(newProfileId, newMetadata);

        Registry.Profile memory profile = registry().getProfileById(newProfileId);
        assertEq(profile.metadata.protocol, newMetadata.protocol, "metadata.protocol");
        assertEq(profile.metadata.pointer, newMetadata.pointer, "metadata.pointer");
    }

    function test_updateProfileMetadataForInvalidId() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce, address(this));
        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.prank(profile1_owner());
        registry().updateProfileMetadata(invalidProfileId, newMetadata);
    }

    function testRevert_updateProfileMetadata_UNAUTHORIZED() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(profile1_notAMember());
        registry().updateProfileMetadata(newProfileId, newMetadata);
    }

    function test_create_anchor() public {
        // create profile
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());
        Registry.Profile memory profile = registry().getProfileById(newProfileId);
        Anchor _anchor = Anchor(payable(profile.anchor));

        assertEq(address(registry()), address(_anchor.registry()), "wrong anchor registry");
    }

    function test_isOwnerOrMemberOfProfile() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        assertTrue(registry().isOwnerOrMemberOfProfile(newProfileId, profile1_owner()), "isOwner");
        assertTrue(registry().isOwnerOrMemberOfProfile(newProfileId, profile1_member1()), "ismember");
        assertFalse(registry().isOwnerOrMemberOfProfile(newProfileId, profile1_notAMember()), "notAMember");
    }

    function test_isOwnerOfProfile() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        assertTrue(registry().isOwnerOfProfile(newProfileId, profile1_owner()), "isOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, profile1_member1()), "notAnOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, profile1_notAMember()), "notAMember");
    }

    function test_isMemberOfProfile() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, profile1_member1()), "member");
        assertFalse(registry().isMemberOfProfile(newProfileId, profile1_notAMember()), "notAMember");
    }

    function test_addMembers() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        assertFalse(registry().isMemberOfProfile(newProfileId, profile1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, profile1_member2()), "member2 not added");

        vm.prank(profile1_owner());
        registry().addMembers(newProfileId, profile1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, profile1_member1()), "member1 added");
        assertTrue(registry().isMemberOfProfile(newProfileId, profile1_member2()), "member2 added");
    }

    function testRevert_addMembers_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.prank(profile1_member1());
        vm.expectRevert(UNAUTHORIZED.selector);
        registry().addMembers(newProfileId, profile1_members());
    }

    function testRevert_addMembers_INVALID_ID() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.prank(profile1_owner());
        registry().addMembers(invalidProfileId, profile1_members());
    }

    function testRevert_addMembers_ZERO_ADDRESS() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.expectRevert(ZERO_ADDRESS.selector);

        address[] memory _members = new address[](1);
        _members[0] = address(0);

        vm.prank(profile1_owner());
        registry().addMembers(newProfileId, _members);
    }

    function test_removeMembers() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());

        assertTrue(registry().isMemberOfProfile(newProfileId, profile1_member1()), "member1 added");
        assertTrue(registry().isMemberOfProfile(newProfileId, profile1_member2()), "member2 added");

        vm.prank(profile1_owner());
        registry().removeMembers(newProfileId, profile1_members());

        assertFalse(registry().isMemberOfProfile(newProfileId, profile1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, profile1_member2()), "member2 not added");
    }

    function testRevert_removeMembers_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.prank(profile1_member1());
        vm.expectRevert(UNAUTHORIZED.selector);
        registry().removeMembers(newProfileId, profile1_members());
    }

    function testRevert_removeMembers_INVALID_ID() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.prank(profile1_owner());
        registry().removeMembers(invalidProfileId, profile1_members());
    }

    function test_removeMembers_NON_EXISTING_MEMBERS() public {
        vm.prank(profile1_owner());
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), profile1_members());
        assertFalse(registry().isMemberOfProfile(newProfileId, profile2_member1()), "member1 not added");
        assertFalse(registry().isMemberOfProfile(newProfileId, profile2_member2()), "member2 not added");
        vm.prank(profile1_owner());
        // Try to remove non-existing members
        registry().removeMembers(newProfileId, profile2_members());
    }

    function test_updateProfilePendingprofile1_owner() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.expectEmit(true, false, false, true);
        emit ProfilePendingOwnerUpdated(newProfileId, profile1_notAMember());

        vm.prank(profile1_owner());
        registry().updateProfilePendingOwner(newProfileId, profile1_notAMember());
        address pendingOwner = registry().profileIdToPendingOwner(newProfileId);

        assertEq(pendingOwner, profile1_notAMember(), "after: pendingOwner");
    }

    function testRevert_updateProfilePendingOwner_UNAUTHORIZED() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.prank(profile1_member1());
        vm.expectRevert(UNAUTHORIZED.selector);
        registry().updateProfilePendingOwner(newProfileId, profile1_notAMember());
    }

    function test_acceptProfileOwnership() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.prank(profile1_owner());
        registry().updateProfilePendingOwner(newProfileId, profile1_notAMember());

        assertTrue(registry().isOwnerOfProfile(newProfileId, profile1_owner()), "before: isOwner");
        assertFalse(registry().isOwnerOfProfile(newProfileId, profile1_notAMember()), "before: notAnOwner");
        address pendingOwner = registry().profileIdToPendingOwner(newProfileId);
        assertEq(pendingOwner, profile1_notAMember(), "before: pendingOwner");

        vm.expectEmit(true, false, false, true);
        emit ProfileOwnerUpdated(newProfileId, profile1_notAMember());

        vm.prank(profile1_notAMember());
        registry().acceptProfileOwnership(newProfileId);

        assertFalse(registry().isOwnerOfProfile(newProfileId, profile1_owner()), "after: notAnOwner");
        assertTrue(registry().isOwnerOfProfile(newProfileId, profile1_notAMember()), "after: isOwner");
        assertEq(registry().profileIdToPendingOwner(newProfileId), address(0), "after: pendingOwner");
    }

    function testRevert_acceptProfileOwnership_NOT_PENDING_profile1_owner() public {
        bytes32 newProfileId = registry().createProfile(nonce, name, metadata, profile1_owner(), new address[](0));

        vm.prank(profile1_owner());
        registry().updateProfilePendingOwner(newProfileId, profile1_notAMember());

        vm.prank(profile1_owner());
        vm.expectRevert(NOT_PENDING_OWNER.selector);
        registry().acceptProfileOwnership(newProfileId);
    }

    function testRevert_acceptProfileOwnership_INVALID_ID() public {
        bytes32 invalidProfileId = TestUtilities._testUtilGenerateProfileId(nonce + 1, address(this));
        vm.expectRevert(NOT_PENDING_OWNER.selector);
        vm.prank(profile1_notAMember());
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
        vm.expectRevert(ZERO_ADDRESS.selector);
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
