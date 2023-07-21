// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../shared/RegistrySetup.sol";

import {Registry} from "../../../contracts/core/Registry.sol";
import {IRegistry} from "../../../contracts/core/IRegistry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {TestUtilities} from "../utils/TestUtilities.sol";

contract RegistryTest is Test, RegistrySetup {
    event IdentityCreated(
        bytes32 indexed identityId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    event IdentityNameUpdated(bytes32 indexed identityId, string name, address anchor);
    event IdentityMetadataUpdated(bytes32 indexed identityId, Metadata metadata);
    event IdentityOwnerUpdated(bytes32 indexed identityId, address owner);
    event IdentityPendingOwnerUpdated(bytes32 indexed identityId, address pendingOwner);

    Metadata public metadata;
    string public name;
    uint256 public nonce;

    function setUp() public {
        __RegistrySetup();
        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        nonce = 2;
    }

    function test_createIdentity() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testIdentityId = TestUtilities._testUtilGenerateIdentityId(nonce, address(this));
        address testAnchor = TestUtilities._testUtilGenerateAnchor(testIdentityId, name);

        emit IdentityCreated(testIdentityId, nonce, name, metadata, identity1_owner(), testAnchor);

        // create identity
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        // Check if the new identity was created
        Registry.Identity memory identity = registry().getIdentityById(newIdentityId);

        assertEq(testIdentityId, newIdentityId, "identityId");

        assertEq(identity.id, newIdentityId, "newIdentityId");
        assertEq(identity.name, name, "name");
        assertEq(identity.metadata.protocol, metadata.protocol, "metadata.protocol");
        assertEq(identity.metadata.pointer, metadata.pointer, "metadata.pointer");
        assertEq(registry().anchorToIdentityId(identity.anchor), newIdentityId, "anchorToIdentityId");

        Registry.Identity memory identityByAnchor = registry().getIdentityByAnchor(identity.anchor);
        assertEq(identityByAnchor.name, name, "getIdentityByAnchor: name");
    }

    function testRevert_createIdentity_NONCE_NOT_AVAILABLE() public {
        // create identity
        registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.NONCE_NOT_AVAILABLE.selector);

        // create identity with same index and name
        registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());
    }

    function test_updateIdentityName() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        string memory newName = "New Name";
        address testAnchor = TestUtilities._testUtilGenerateAnchor(newIdentityId, newName);
        vm.expectEmit(true, false, false, true);
        emit IdentityNameUpdated(newIdentityId, newName, testAnchor);
        Registry.Identity memory identity = registry().getIdentityById(newIdentityId);

        vm.prank(identity1_owner());
        address newAnchor = registry().updateIdentityName(newIdentityId, newName);

        assertEq(registry().getIdentityById(newIdentityId).name, newName, "name");
        // old and new anchor should be mapped to identityId
        assertEq(registry().anchorToIdentityId(identity.anchor), bytes32(0), "old anchor");
        assertEq(registry().anchorToIdentityId(newAnchor), newIdentityId, "new anchor");
    }

    function testRevert_updateIdentityNameForInvalidId() public {
        bytes32 invalidIdentityId = TestUtilities._testUtilGenerateIdentityId(nonce, address(this));
        string memory newName = "New Name";

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        vm.prank(identity1_owner());
        registry().updateIdentityName(invalidIdentityId, newName);
    }

    function testRevert_updateIdentityName_UNAUTHORIZED() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(identity1_member1());
        registry().updateIdentityName(newIdentityId, newName);
    }

    function testRevert_updateIdentityName_UNAUTHORIZED_bymember() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        string memory newName = "New Name";

        vm.prank(identity1_member1());
        registry().updateIdentityName(newIdentityId, newName);
    }

    function test_updateIdentityMetadata_byidentity1_owner() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectEmit(true, false, false, true);
        emit IdentityMetadataUpdated(newIdentityId, newMetadata);

        vm.prank(identity1_owner());
        registry().updateIdentityMetadata(newIdentityId, newMetadata);

        Registry.Identity memory identity = registry().getIdentityById(newIdentityId);
        assertEq(identity.metadata.protocol, newMetadata.protocol, "metadata.protocol");
        assertEq(identity.metadata.pointer, newMetadata.pointer, "metadata.pointer");
    }

    function test_updateIdentityMetadataForInvalidId() public {
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        bytes32 invalidIdentityId = TestUtilities._testUtilGenerateIdentityId(nonce, address(this));
        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.prank(identity1_owner());
        registry().updateIdentityMetadata(invalidIdentityId, newMetadata);
    }

    function testRevert_updateIdentityMetadata_UNAUTHORIZED() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);

        vm.prank(identity1_notAMember());
        registry().updateIdentityMetadata(newIdentityId, newMetadata);
    }

    function test_isOwnerOrMemberOfIdentity() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isOwnerOrMemberOfIdentity(newIdentityId, identity1_owner()), "isOwner");
        assertTrue(registry().isOwnerOrMemberOfIdentity(newIdentityId, identity1_member1()), "ismember");
        assertFalse(registry().isOwnerOrMemberOfIdentity(newIdentityId, identity1_notAMember()), "notAMember");
    }

    function test_isOwnerOfIdentity() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isOwnerOfIdentity(newIdentityId, identity1_owner()), "isOwner");
        assertFalse(registry().isOwnerOfIdentity(newIdentityId, identity1_member1()), "notAnOwner");
        assertFalse(registry().isOwnerOfIdentity(newIdentityId, identity1_notAMember()), "notAMember");
    }

    function test_isMemberOfIdentity() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isMemberOfIdentity(newIdentityId, identity1_member1()), "member");
        assertFalse(registry().isMemberOfIdentity(newIdentityId, identity1_notAMember()), "notAMember");
    }

    function test_addMembers() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        assertFalse(registry().isMemberOfIdentity(newIdentityId, identity1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfIdentity(newIdentityId, identity1_member2()), "member2 not added");

        vm.prank(identity1_owner());
        registry().addMembers(newIdentityId, identity1_members());

        assertTrue(registry().isMemberOfIdentity(newIdentityId, identity1_member1()), "member1 added");
        assertTrue(registry().isMemberOfIdentity(newIdentityId, identity1_member2()), "member2 added");
    }

    function testRevert_addMembers_UNAUTHORIZED() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().addMembers(newIdentityId, identity1_members());
    }

    function test_removeMembers() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), identity1_members());

        assertTrue(registry().isMemberOfIdentity(newIdentityId, identity1_member1()), "member1 added");
        assertTrue(registry().isMemberOfIdentity(newIdentityId, identity1_member2()), "member2 added");

        vm.prank(identity1_owner());
        registry().removeMembers(newIdentityId, identity1_members());

        assertFalse(registry().isMemberOfIdentity(newIdentityId, identity1_member1()), "member1 not added");
        assertFalse(registry().isMemberOfIdentity(newIdentityId, identity1_member2()), "member2 not added");
    }

    function testRevert_removeMembers_UNAUTHORIZED() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().removeMembers(newIdentityId, identity1_members());
    }

    function test_updateIdentityPendingidentity1_owner() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.expectEmit(true, false, false, true);
        emit IdentityPendingOwnerUpdated(newIdentityId, identity1_notAMember());

        vm.prank(identity1_owner());
        registry().updateIdentityPendingOwner(newIdentityId, identity1_notAMember());
        address pendingOwner = registry().identityIdToPendingOwner(newIdentityId);

        assertEq(pendingOwner, identity1_notAMember(), "after: pendingOwner");
    }

    function testRevert_updateIdentityPendingOwner_UNAUTHORIZED() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_member1());
        vm.expectRevert(IRegistry.UNAUTHORIZED.selector);
        registry().updateIdentityPendingOwner(newIdentityId, identity1_notAMember());
    }

    function test_acceptIdentityOwnership() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_owner());
        registry().updateIdentityPendingOwner(newIdentityId, identity1_notAMember());

        assertTrue(registry().isOwnerOfIdentity(newIdentityId, identity1_owner()), "before: isOwner");
        assertFalse(registry().isOwnerOfIdentity(newIdentityId, identity1_notAMember()), "before: notAnOwner");
        address pendingOwner = registry().identityIdToPendingOwner(newIdentityId);
        assertEq(pendingOwner, identity1_notAMember(), "before: pendingOwner");

        vm.expectEmit(true, false, false, true);
        emit IdentityOwnerUpdated(newIdentityId, identity1_notAMember());

        vm.prank(identity1_notAMember());
        registry().acceptIdentityOwnership(newIdentityId);

        assertFalse(registry().isOwnerOfIdentity(newIdentityId, identity1_owner()), "after: notAnOwner");
        assertTrue(registry().isOwnerOfIdentity(newIdentityId, identity1_notAMember()), "after: isOwner");
        assertEq(registry().identityIdToPendingOwner(newIdentityId), address(0), "after: pendingOwner");
    }

    function testRevert_acceptIdentityOwnership_NOT_PENDING_identity1_owner() public {
        bytes32 newIdentityId = registry().createIdentity(nonce, name, metadata, identity1_owner(), new address[](0));

        vm.prank(identity1_owner());
        registry().updateIdentityPendingOwner(newIdentityId, identity1_notAMember());

        vm.prank(identity1_owner());
        vm.expectRevert(IRegistry.NOT_PENDING_OWNER.selector);
        registry().acceptIdentityOwnership(newIdentityId);
    }
}
