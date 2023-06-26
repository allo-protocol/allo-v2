pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

contract RegistryTest is Test {
    event IdentityCreated(bytes32 indexed identityId, uint256 index, string name, Metadata metadata, address anchor);

    event IdentityNameUpdated(bytes32 indexed identityId, string name, address anchor);

    event IdentityMetadataUpdated(bytes32 indexed identityId, Metadata metadata);

    Registry public registry;

    address public owner;
    address public member1;
    address public member2;
    address[] public members;
    address public notAMember;

    Metadata public metadata;
    string public name;
    uint256 public index;

    function setUp() public {
        notAMember = makeAddr("notAMember");

        owner = makeAddr("owner");
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");

        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        index = 2;

        registry = new Registry();

        members = new address[](2);
        members[0] = member1;
        members[1] = member2;
    }

    function test_createIdentity() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testIdentityId = _testUtilGenerateIdentityId(index, address(this));
        address testAnchor = _testUtilGenerateAnchor(testIdentityId, name);

        emit IdentityCreated(testIdentityId, index, name, metadata, testAnchor);

        // create identity
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        // Check if the new identity was created
        Registry.Identity memory identity = registry.getIdentity(newIdentityId);

        assertEq(identity.id, newIdentityId, "identityId");
        assertEq(identity.name, name, "name");
        assertEq(identity.metadata.protocol, metadata.protocol, "metadata.protocol");
        assertEq(identity.metadata.pointer, metadata.pointer, "metadata.pointer");
        assertEq(registry.anchorToIdentityId(identity.anchor), newIdentityId, "anchorToIdentityId");
    }

    function testRevert_createIdentity_INDEX_NOT_AVAILABLE() public {
        // create identity
        registry.createIdentity(index, name, metadata, owner, members);

        vm.expectRevert(Registry.INDEX_NOT_AVAILABLE.selector);

        // create identity with same index and name
        registry.createIdentity(index, name, metadata, owner, members);
    }

    function test_updateIdentityName() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        string memory newName = "New Name";
        address testAnchor = _testUtilGenerateAnchor(newIdentityId, newName);
        vm.expectEmit(true, false, false, true);
        emit IdentityNameUpdated(newIdentityId, newName, testAnchor);
        Registry.Identity memory identity = registry.getIdentity(newIdentityId);

        vm.prank(owner);
        address newAnchor = registry.updateIdentityName(newIdentityId, newName);

        assertEq(registry.getIdentity(newIdentityId).name, newName, "name");
        // old and new anchor should be mapped to identityId
        assertEq(registry.anchorToIdentityId(identity.anchor), newIdentityId, "old anchor");
        assertEq(registry.anchorToIdentityId(newAnchor), newIdentityId, "new anchor");
    }

    function test_updateIdentityNameForInvalidId() public {
        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);
        bytes32 invalidIdentityId = _testUtilGenerateIdentityId(index, address(this));
        string memory newName = "New Name";

        vm.prank(owner);
        registry.updateIdentityName(invalidIdentityId, newName);
    }

    function testRevert_updateIdentityName_NO_ACCESS_TO_ROLE() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);

        string memory newName = "New Name";

        vm.prank(member1);
        registry.updateIdentityName(newIdentityId, newName);
    }

    function testRevert_updateIdentityName_NO_ACCESS_TO_ROLE_byMember() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);

        string memory newName = "New Name";

        vm.prank(member1);
        registry.updateIdentityName(newIdentityId, newName);
    }

    function test_updateIdentityMetadata_byOwner() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectEmit(true, false, false, true);
        emit IdentityMetadataUpdated(newIdentityId, newMetadata);

        vm.prank(owner);
        registry.updateIdentityMetadata(newIdentityId, newMetadata);

        Registry.Identity memory identity = registry.getIdentity(newIdentityId);
        assertEq(identity.metadata.protocol, newMetadata.protocol, "metadata.protocol");
        assertEq(identity.metadata.pointer, newMetadata.pointer, "metadata.pointer");
    }

    function test_updateIdentityMetadata_byMember() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectEmit(true, false, false, true);
        emit IdentityMetadataUpdated(newIdentityId, newMetadata);

        vm.prank(member2);
        registry.updateIdentityMetadata(newIdentityId, newMetadata);

        Registry.Identity memory identity = registry.getIdentity(newIdentityId);
        assertEq(identity.metadata.protocol, newMetadata.protocol, "metadata.protocol");
        assertEq(identity.metadata.pointer, newMetadata.pointer, "metadata.pointer");
    }

    function test_updateIdentityMetadataForInvalidId() public {
        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);
        bytes32 invalidIdentityId = _testUtilGenerateIdentityId(index, address(this));
        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.prank(owner);
        registry.updateIdentityMetadata(invalidIdentityId, newMetadata);
    }

    function testRevert_updateIdentityMetadata_NO_ACCESS_TO_ROLE() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        Metadata memory newMetadata = Metadata({protocol: 1, pointer: "new metadata"});

        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);

        vm.prank(notAMember);
        registry.updateIdentityMetadata(newIdentityId, newMetadata);
    }

    function test_isOwnerOfIdentity() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        assertTrue(registry.isOwnerOfIdentity(newIdentityId, owner), "isOwner");
        assertFalse(registry.isOwnerOfIdentity(newIdentityId, member1), "notAnOwner");
        assertFalse(registry.isOwnerOfIdentity(newIdentityId, notAMember), "notAMember");
    }

    function test_isMemberOfIdentity() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        assertTrue(registry.isMemberOfIdentity(newIdentityId, member1), "member");
        assertFalse(registry.isMemberOfIdentity(newIdentityId, notAMember), "notAMember");
    }

    function test_addMembers() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, new address[](0));

        assertFalse(registry.isMemberOfIdentity(newIdentityId, member1), "member1 not added");
        assertFalse(registry.isMemberOfIdentity(newIdentityId, member2), "member2 not added");

        vm.prank(owner);
        registry.addMembers(newIdentityId, members);

        assertTrue(registry.isMemberOfIdentity(newIdentityId, member1), "member1 added");
        assertTrue(registry.isMemberOfIdentity(newIdentityId, member2), "member2 added");
    }

    function testRevert_addMembers_NO_ACCESS_TO_ROLE() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, new address[](0));

        vm.prank(member1);
        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);
        registry.addMembers(newIdentityId, members);
    }

    function test_removeMembers() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, members);

        assertTrue(registry.isMemberOfIdentity(newIdentityId, member1), "member1 added");
        assertTrue(registry.isMemberOfIdentity(newIdentityId, member2), "member2 added");

        vm.prank(owner);
        registry.removeMembers(newIdentityId, members);

        assertFalse(registry.isMemberOfIdentity(newIdentityId, member1), "member1 not added");
        assertFalse(registry.isMemberOfIdentity(newIdentityId, member2), "member2 not added");
    }

    function testRevert_removeMembers_NO_ACCESS_TO_ROLE() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, new address[](0));

        vm.prank(member1);
        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);
        registry.removeMembers(newIdentityId, members);
    }

    function test_changeIdentityOwner() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, new address[](0));

        assertTrue(registry.isOwnerOfIdentity(newIdentityId, owner), "before: isOwner");
        assertTrue(registry.isMemberOfIdentity(newIdentityId, owner), "before: isMember");
        assertFalse(registry.isOwnerOfIdentity(newIdentityId, notAMember), "before: notAnOwner");
        assertFalse(registry.isMemberOfIdentity(newIdentityId, notAMember), "before: notAMember");

        vm.prank(owner);
        registry.changeIdentityOwner(newIdentityId, notAMember);

        assertFalse(registry.isOwnerOfIdentity(newIdentityId, owner), "after: notAnOwner");
        assertTrue(registry.isMemberOfIdentity(newIdentityId, owner), "before: isMember");
        assertTrue(registry.isOwnerOfIdentity(newIdentityId, notAMember), "after: isOwner");
        assertTrue(registry.isMemberOfIdentity(newIdentityId, notAMember), "after: isMember");
    }

    function testRevert_changeIdentityOwner_NO_ACCESS_TO_ROLE() public {
        bytes32 newIdentityId = registry.createIdentity(index, name, metadata, owner, new address[](0));

        vm.prank(member1);
        vm.expectRevert(Registry.NO_ACCESS_TO_ROLE.selector);
        registry.changeIdentityOwner(newIdentityId, notAMember);
    }

    /// @notice Generates the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _testUtilGenerateAnchor(bytes32 _identityId, string memory _name) internal pure returns (address) {
        bytes32 attestationHash = keccak256(abi.encodePacked(_identityId, _name));

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the identityId based on msg.sender
    /// @param _index Index of the identity
    function _testUtilGenerateIdentityId(uint256 _index, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index, sender));
    }
}
