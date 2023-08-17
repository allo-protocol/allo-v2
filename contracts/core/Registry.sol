// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// External Libraries
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {CREATE3} from "solady/src/utils/CREATE3.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
// Interfaces
import "./IRegistry.sol";
// Internal Libraries
import {Anchor} from "./Anchor.sol";
import {Metadata} from "./libraries/Metadata.sol";
import "./libraries/Native.sol";
import "./libraries/Transfer.sol";

/// @title Registry
/// @notice Registry contract for profiles
/// @dev This contract is used to create and manage profiles
/// @author allo-team
contract Registry is IRegistry, Native, AccessControl, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice anchor -> Profile.id
    mapping(address => bytes32) public anchorToProfileId;

    /// @notice Profile.id -> Profile
    mapping(bytes32 => Profile) public profilesById;

    /// @notice Profile.id -> pending owner
    mapping(bytes32 => address) public profileIdToPendingOwner;

    /// @notice Allo Owner Role for fund recovery
    bytes32 public constant ALLO_OWNER = keccak256("ALLO_OWNER");

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the owner of the profile
    modifier onlyProfileOwner(bytes32 _profileId) {
        if (!isOwnerOfProfile(_profileId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    constructor(address _owner) {
        if (_owner == address(0)) {
            revert ZERO_ADDRESS();
        }
        _grantRole(ALLO_OWNER, _owner);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Retrieve profile by profileId
    /// @param profileId The profileId of the profile
    function getProfileById(bytes32 profileId) public view returns (Profile memory) {
        return profilesById[profileId];
    }

    /// @notice Retrieve profile by anchor
    /// @param _anchor The anchor of the profile
    function getProfileByAnchor(address _anchor) public view returns (Profile memory) {
        bytes32 profileId = anchorToProfileId[_anchor];
        return profilesById[profileId];
    }

    /// @notice Creates a new profile
    /// @dev This will also set the attestation address generated from msg.sender and name
    /// @param _nonce Nonce used to generate profileId
    /// @param _name The name of the profile
    /// @param _metadata The metadata of the profile
    /// @param _members The members of the profile
    /// @param _owner The owner of the profile
    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32) {
        bytes32 profileId = _generateProfileId(_nonce);

        if (profilesById[profileId].anchor != address(0)) {
            revert NONCE_NOT_AVAILABLE();
        }

        if (_owner == address(0)) {
            revert ZERO_ADDRESS();
        }

        Profile memory profile = Profile({
            id: profileId,
            nonce: _nonce,
            name: _name,
            metadata: _metadata,
            owner: _owner,
            anchor: _generateAnchor(profileId, _name)
        });

        profilesById[profileId] = profile;
        anchorToProfileId[profile.anchor] = profileId;

        // assign roles
        uint256 memberLength = _members.length;
        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }
            _grantRole(profileId, member);
            unchecked {
                i++;
            }
        }

        emit ProfileCreated(profileId, profile.nonce, profile.name, profile.metadata, profile.owner, profile.anchor);

        return profileId;
    }

    /// @notice Updates the name of the profile and generates new anchor
    /// @param _profileId The profileId of the profile
    /// @param _name The new name of the profile
    /// @dev Only owner can update the name.
    function updateProfileName(bytes32 _profileId, string memory _name)
        external
        onlyProfileOwner(_profileId)
        returns (address)
    {
        address anchor = _generateAnchor(_profileId, _name);

        Profile storage profile = profilesById[_profileId];
        profile.name = _name;

        // remove old anchor
        anchorToProfileId[profile.anchor] = bytes32(0);

        // set new anchor
        profile.anchor = anchor;
        anchorToProfileId[anchor] = _profileId;

        emit ProfileNameUpdated(_profileId, _name, anchor);

        // TODO: should we return profile
        return anchor;
    }

    /// @notice update the metadata of the profile
    /// @param _profileId The profileId of the profile
    /// @param _metadata The new metadata of the profile
    /// @dev Only owner can update metadata
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata)
        external
        onlyProfileOwner(_profileId)
    {
        profilesById[_profileId].metadata = _metadata;

        emit ProfileMetadataUpdated(_profileId, _metadata);
    }

    /// @notice Returns if the given address is an owner or member of the profile
    /// @param _profileId The profileId of the profile
    /// @param _account The address to check
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) public view returns (bool) {
        return isOwnerOfProfile(_profileId, _account) || isMemberOfProfile(_profileId, _account);
    }

    /// @notice Returns if the given address is an owner of the profile
    /// @param _profileId The profileId of the profile
    /// @param _owner The address to check
    function isOwnerOfProfile(bytes32 _profileId, address _owner) public view returns (bool) {
        return profilesById[_profileId].owner == _owner;
    }

    /// @notice Returns if the given address is an member of the profile
    /// @param _profileId The profileId of the profile
    /// @param _member The address to check
    function isMemberOfProfile(bytes32 _profileId, address _member) public view returns (bool) {
        return hasRole(_profileId, _member);
    }

    /// @notice Updates the pending owner of the profile
    /// @param _profileId The profileId of the profile
    /// @param _pendingOwner New pending owner
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner)
        external
        onlyProfileOwner(_profileId)
    {
        profileIdToPendingOwner[_profileId] = _pendingOwner;

        emit ProfilePendingOwnerUpdated(_profileId, _pendingOwner);
    }

    /// @notice Transfers the ownership of the profile to the pending owner
    /// @param _profileId The profileId of the profile
    /// @dev Only pending owner can claim ownership.
    function acceptProfileOwnership(bytes32 _profileId) external {
        Profile storage profile = profilesById[_profileId];
        address newOwner = profileIdToPendingOwner[_profileId];

        if (msg.sender != newOwner) {
            revert NOT_PENDING_OWNER();
        }

        profile.owner = newOwner;
        delete profileIdToPendingOwner[_profileId];

        emit ProfileOwnerUpdated(_profileId, profile.owner);
    }

    /// @notice Adds members to the profile
    /// @param _profileId The profileId of the profile
    /// @param _members The members to add
    /// @dev Only owner can add members
    function addMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }
            _grantRole(_profileId, member);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Removes members from the profile
    /// @param _profileId The profileId of the profile
    /// @param _members The members to remove
    /// @dev Only owner can remove members
    function removeMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        for (uint256 i = 0; i < memberLength;) {
            _revokeRole(_profileId, _members[i]);
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ======== Internal Functions ========
    /// ====================================

    /// @notice Generates and deploy the anchor for the given profileId and name
    /// @param _profileId Id of the profile
    /// @param _name The name of the profile
    function _generateAnchor(bytes32 _profileId, string memory _name) internal returns (address anchor) {
        bytes32 salt = keccak256(abi.encodePacked(_profileId, _name));

        bytes memory creationCode = abi.encodePacked(type(Anchor).creationCode, abi.encode(_profileId));

        anchor = CREATE3.deploy(salt, creationCode, 0);
    }

    /// @notice Generates the profileId based on msg.sender
    /// @param _nonce Nonce used to generate profileId
    function _generateProfileId(uint256 _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, msg.sender));
    }

    /// @notice Transfer thefunds recovered  to the recipient
    /// @param _token The address of the token to transfer
    /// @param _recipient The address of the recipient
    function recoverFunds(address _token, address _recipient) external onlyRole(ALLO_OWNER) {
        if (_recipient == address(0)) {
            revert ZERO_ADDRESS();
        }
        uint256 amount = _token == NATIVE ? address(this).balance : ERC20(_token).balanceOf(address(this));
        _transferAmount(_token, _recipient, amount);
    }
}
