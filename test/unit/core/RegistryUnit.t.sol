// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {MockMockRegistry} from "test/smock/MockMockRegistry.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IAccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";

contract RegistryUnit is Test {
    using stdStorage for StdStorage;

    MockMockRegistry public registry;

    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);

    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);

    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);

    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    function setUp() public virtual {
        registry = new MockMockRegistry();
    }

    modifier givenCallerIsProfileOwner(bytes32 _profileId) {
        registry.mock_call__checkOnlyProfileOwner(_profileId);
        _;
    }

    modifier givenCallerIsAlloOwner() {
        registry.mock_call__checkRole(keccak256("ALLO_OWNER"), address(this));
        _;
    }

    function test_InitializeRevertWhen_OwnerIsZeroAddress() external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        registry.initialize(address(0));
    }

    function test_InitializeWhenOwnerIsNotZeroAddress(address _owner) external {
        vm.assume(_owner != address(0));
        // it should call _grantRole
        registry.expectCall__grantRole(keccak256("ALLO_OWNER"), _owner);

        vm.prank(_owner);
        registry.initialize(_owner);

        assertTrue(registry.hasRole(keccak256("ALLO_OWNER"), _owner));
    }

    function test_CreateProfileRevertWhen_ProfileAlreadyExists(uint256 _nonce, address _owner) external {
        vm.assume(_owner != address(0));
        address[] memory _members = new address[](1);
        _members[0] = makeAddr("member");

        // mock call _generateProfileId
        bytes32 _expectedProfileId = keccak256(abi.encodePacked(_nonce, _owner));
        registry.mock_call__generateProfileId(_nonce, _owner, _expectedProfileId);

        address _mockAnchor = makeAddr("anchor");
        registry.mock_call__generateAnchor(_expectedProfileId, "test", _mockAnchor);

        vm.prank(_owner);
        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, _members);

        registry.mock_call__generateProfileId(_nonce, _owner, _expectedProfileId);
        // it should revert
        vm.expectRevert(Errors.NONCE_NOT_AVAILABLE.selector);
        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, _members);
    }

    function test_CreateProfileRevertWhen_ProfileOwnerIsZeroAddress(uint256 _nonce, address[] memory _members)
        external
    {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), address(0), _members);
    }

    function test_CreateProfileRevertWhen_ProfileMembersAreHigherThanZeroAndOwnerIsNotTheCaller(
        uint256 _nonce,
        address _owner,
        address[] memory members
    ) external {
        vm.assume(members.length > 0);
        vm.assume(_owner != address(0));
        vm.assume(_owner != address(this));
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, members);
    }

    function test_CreateProfileRevertWhen_ProfileMemberAddressIsZero(uint256 _nonce, address _owner) external {
        vm.assume(_owner != address(0));

        address[] memory _members = new address[](1);
        _members[0] = address(0);

        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        vm.prank(_owner);
        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, _members);
    }

    function test_CreateProfileWhenCalledWithCorrectParams(uint256 _nonce, address _owner) external {
        vm.assume(_owner != address(0));
        address[] memory _members = new address[](1);
        _members[0] = makeAddr("member");

        // it should call _generateProfileId
        registry.expectCall__generateProfileId(_nonce, _owner);
        // it should call _generateAnchor
        bytes32 _expectedProfileId = keccak256(abi.encodePacked(_nonce, _owner));
        address _mockAnchor = makeAddr("anchor");

        registry.mock_call__generateAnchor(_expectedProfileId, "test", _mockAnchor);
        registry.expectCall__generateAnchor(_expectedProfileId, "test");
        // it should call _grantRole for members
        registry.expectCall__grantRole(_expectedProfileId, _members[0]);
        // it should emit ProfileCreated event
        vm.expectEmit(true, true, true, true);
        emit ProfileCreated(
            _expectedProfileId, _nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, _mockAnchor
        );

        vm.prank(_owner);
        registry.createProfile(_nonce, "test", Metadata({protocol: 1, pointer: "0x"}), _owner, _members);
    }

    function test_UpdateProfileNameShouldCall_generateAnchor(string memory _name, bytes32 _profileId)
        external
        givenCallerIsProfileOwner(_profileId)
    {
        // it should call _generateAnchor
        address _anchor = makeAddr("anchor");
        registry.expectCall__generateAnchor(_profileId, _name);
        registry.mock_call__generateAnchor(_profileId, _name, _anchor);

        address _profileAnchor = registry.updateProfileName(_profileId, _name);
        assertEq(_profileAnchor, _anchor);
    }

    function test_UpdateProfileNameShouldEmitProfileNameUpdatedEvent(string memory _name, bytes32 _profileId)
        external
        givenCallerIsProfileOwner(_profileId)
    {
        // it should call _generateAnchor
        address _anchor = makeAddr("anchor");
        registry.expectCall__generateAnchor(_profileId, _name);
        registry.mock_call__generateAnchor(_profileId, _name, _anchor);

        // it should emit ProfileNameUpdated event
        vm.expectEmit(true, true, true, true);
        emit ProfileNameUpdated(_profileId, _name, _anchor);

        registry.updateProfileName(_profileId, _name);
    }

    function test_UpdateProfileMetadataShouldEmitProfileMetadataUpdatedEvent(
        bytes32 _profileId,
        Metadata memory _metadata
    ) external givenCallerIsProfileOwner(_profileId) {
        // it should emit ProfileMetadataUpdated event
        vm.expectEmit(true, true, true, true);
        emit ProfileMetadataUpdated(_profileId, _metadata);

        registry.updateProfileMetadata(_profileId, _metadata);
    }

    function test_IsOwnerOrMemberOfProfileWhenCalled(bytes32 _profileId, address _account) external {
        // it should call _isOwnerOfProfile
        registry.mock_call__isOwnerOfProfile(_profileId, _account, false);
        registry.expectCall__isOwnerOfProfile(_profileId, _account);
        // it should call _isMemberOfProfile
        registry.mock_call__isMemberOfProfile(_profileId, _account, true);
        registry.expectCall__isMemberOfProfile(_profileId, _account);

        assertTrue(registry.isOwnerOrMemberOfProfile(_profileId, _account));
    }

    function test_IsOwnerOfProfileWhenCalled(bytes32 _profileId, address _owner) external {
        // it should call _isOwnerOfProfile
        registry.mock_call__isOwnerOfProfile(_profileId, _owner, true);
        registry.expectCall__isOwnerOfProfile(_profileId, _owner);

        assertTrue(registry.isOwnerOfProfile(_profileId, _owner));
    }

    function test_IsMemberOfProfileWhenCalled(bytes32 _profileId, address _member) external {
        // it should call _isMemberOfProfile
        registry.mock_call__isMemberOfProfile(_profileId, _member, true);
        registry.expectCall__isMemberOfProfile(_profileId, _member);

        assertTrue(registry.isMemberOfProfile(_profileId, _member));
    }

    function test_UpdateProfilePendingOwnerWhenProfileOwnerIsTheCaller(bytes32 _profileId, address _pendingOwner)
        external
        givenCallerIsProfileOwner(_profileId)
    {
        // it should emit ProfilePendingOwnerUpdated
        vm.expectEmit(true, true, true, true);
        emit ProfilePendingOwnerUpdated(_profileId, _pendingOwner);

        registry.updateProfilePendingOwner(_profileId, _pendingOwner);
        // it should store the pendingOwner to profileIdToPendingOwner
        assertEq(registry.profileIdToPendingOwner(_profileId), _pendingOwner);
    }

    function test_AcceptProfileOwnershipRevertWhen_CallerIsDifferentThanNewOwner(bytes32 _profileId) external {
        address _pendingOwner = makeAddr("pendingOwner");
        stdstore.target(address(registry)).sig("profileIdToPendingOwner(bytes32)").with_key(_profileId).checked_write(
            _pendingOwner
        );

        // it should revert
        vm.expectRevert(Errors.NOT_PENDING_OWNER.selector);
        registry.acceptProfileOwnership(_profileId);
    }

    function test_AcceptProfileOwnershipWhenCalledWithCorrectParams(bytes32 _profileId) external {
        address _pendingOwner = makeAddr("pendingOwner");
        stdstore.target(address(registry)).sig("profileIdToPendingOwner(bytes32)").with_key(_profileId).checked_write(
            _pendingOwner
        );

        // it should emit ProfileOwnerUpdated
        vm.expectEmit(true, true, true, true);
        emit ProfileOwnerUpdated(_profileId, _pendingOwner);

        vm.prank(_pendingOwner);
        registry.acceptProfileOwnership(_profileId);

        // it should delete the pendingOwner from profileIdToPendingOwner
        assertEq(registry.profileIdToPendingOwner(_profileId), address(0));
    }

    function test_AddMembersRevertWhen_MemberIsZeroAddress(bytes32 _profileId)
        external
        givenCallerIsProfileOwner(_profileId)
    {
        address[] memory _members = new address[](1);
        _members[0] = address(0);

        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        registry.addMembers(_profileId, _members);
    }

    function test_AddMembersWhenCalledWithCorrectParams(bytes32 _profileId)
        external
        givenCallerIsProfileOwner(_profileId)
    {
        address[] memory _members = new address[](1);
        _members[0] = makeAddr("member");
        // it should call _grantRole for members
        registry.expectCall__grantRole(_profileId, _members[0]);

        registry.addMembers(_profileId, _members);
    }

    function test_RemoveMembersWhenCalled(bytes32 _profileId) external givenCallerIsProfileOwner(_profileId) {
        address[] memory _members = new address[](1);
        _members[0] = makeAddr("member");

        // it should call _revokeRole for members
        registry.expectCall__revokeRole(_profileId, _members[0]);

        registry.removeMembers(_profileId, _members);
    }

    function test__checkOnlyProfileOwnerRevertWhen_CallerIsNotProfileOwner(bytes32 _profileId) external {
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        registry.call__checkOnlyProfileOwner(_profileId);
    }

    function test__checkOnlyProfileOwnerWhenCallerIsProfileOwner(bytes32 _profileId) external {
        registry.mock_call__isOwnerOfProfile(_profileId, address(this), true);

        // it should not revert
        registry.call__checkOnlyProfileOwner(_profileId);
    }

    function test__generateAnchorWhenAnchorDoesNotExist(bytes32 _profileId, string memory _name) external {
        /// Calculate anchor address
        bytes memory encodedData = abi.encode(_profileId, _name);
        bytes memory encodedConstructorArgs = abi.encode(_profileId, address(registry));

        bytes memory bytecode = abi.encodePacked(type(Anchor).creationCode, encodedConstructorArgs);

        bytes32 salt = keccak256(encodedData);

        address preComputedAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(registry), salt, keccak256(bytecode)))))
        );

        // it should deploy the anchor
        address _anchor = registry.call__generateAnchor(_profileId, _name);

        assertEq(_anchor, preComputedAddress);
    }

    function test__generateAnchorWhenAnchorExists(bytes32 _profileId, string memory _name) external {
        // it should return the anchor address
        address _anchor = registry.call__generateAnchor(_profileId, _name);

        // when called again with same params it should return the same address
        assertEq(_anchor, registry.call__generateAnchor(_profileId, _name));
    }

    function test__generateAnchorRevertWhen_AnchorProfileIdIsNotTheSameAsProvidedProfileId(
        bytes32 _profileId,
        string memory _name
    ) external {
        bytes32 _wrongProfileId = keccak256("wrong");
        vm.assume(_profileId != _wrongProfileId);
        address _anchor = registry.call__generateAnchor(_profileId, _name);
        vm.mockCall(_anchor, abi.encodeWithSignature("profileId()"), abi.encode(_wrongProfileId));

        // it should revert
        vm.expectRevert(Errors.ANCHOR_ERROR.selector);

        registry.call__generateAnchor(_profileId, _name);
    }

    function test__generateProfileIdShouldReturnTheKeccak256OfEncodedNonceAndOwnerAddress(
        uint256 _nonce,
        address _owner
    ) external {
        // it should return the keccak256 of encoded nonce and owner address
        assertEq(keccak256(abi.encodePacked(_nonce, _owner)), registry.call__generateProfileId(_nonce, _owner));
    }

    function test__isOwnerOfProfileWhenProvidedAddressIsOwnerOfProfile(bytes32 _profileId, address _owner) external {
        registry.set_profilesById(
            _profileId,
            IRegistry.Profile({
                id: bytes32(0),
                nonce: 0,
                name: "",
                metadata: Metadata({protocol: 0, pointer: ""}),
                owner: _owner,
                anchor: address(0)
            })
        );

        assertTrue(registry.call__isOwnerOfProfile(_profileId, _owner));
    }

    function test__isOwnerOfProfileWhenProvidedAddressIsNotOwnerOfProfile(bytes32 _profileId, address _owner)
        external
    {
        vm.assume(_owner != address(0));
        // it should return false
        assertTrue(!registry.call__isOwnerOfProfile(_profileId, _owner));
    }

    function test__isMemberOfProfileWhenProvidedAddressIsMemberOfProfile(bytes32 _profileId, address _member)
        external
    {
        vm.mockCall(
            address(registry),
            abi.encodeWithSignature("_isMemberOfProfile(bytes32,address)", _profileId, _member),
            abi.encode(true)
        );
        // it should return true
        assertTrue(registry.call__isMemberOfProfile(_profileId, _member));
    }

    function test__isMemberOfProfileWhenProvidedAddressIsNotMemberOfProfile(bytes32 _profileId, address _member)
        external
    {
        // it should return false
        assertTrue(!registry.call__isMemberOfProfile(_profileId, _member));
    }

    function test_RecoverFundsRevertWhen_RecipientIsZeroAddress(address _token) external givenCallerIsAlloOwner {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        registry.recoverFunds(_token, address(0));
    }

    function test_RecoverFundsWhenRecipientIsNotZeroAddress(address _token, address _recipient, uint256 _amount)
        external
        givenCallerIsAlloOwner
    {
        vm.assume(_recipient != address(0));
        vm.assume(_token != address(vm));

        vm.mockCall(_token, abi.encodeWithSignature("balanceOf(address)", address(registry)), abi.encode(_amount));
        vm.mockCall(_token, abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount), abi.encode(true));

        // it should call getBalance
        vm.expectCall(_token, abi.encodeWithSignature("balanceOf(address)", address(registry)));

        // it should call transfer
        vm.expectCall(_token, abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount));

        registry.recoverFunds(_token, _recipient);
    }
}
