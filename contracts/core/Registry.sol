// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Libraries
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
// Interfaces
import "./interfaces/IRegistry.sol";
// Internal Libraries
import {Anchor} from "./Anchor.sol";
import {Errors} from "./libraries/Errors.sol";
import {Metadata} from "./libraries/Metadata.sol";
import "./libraries/Native.sol";
import "./libraries/Transfer.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Registry Contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Registry contract for creating and managing profiles
/// @dev This contract is used to create and manage profiles for the Allo protocol
///      It is also used to deploy the anchor contract for each profile which acts as a proxy
///      for the profile and is used to receive funds and execute transactions on behalf of the profile
///      The Registry is also used to add and remove members from a profile and update the profile 'Metadata'
contract Registry is IRegistry, Initializable, Native, AccessControlUpgradeable, Transfer, Errors {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice This maps the anchor address to the profile ID
    /// @dev anchor -> Profile.id
    mapping(address => bytes32) public anchorToProfileId;

    /// @notice This maps the profile ID to the profile details
    /// @dev Profile.id -> Profile
    mapping(bytes32 => Profile) public profilesById;

    /// @notice This maps the profile ID to the pending owner
    /// @dev Profile.id -> pending owner
    mapping(bytes32 => address) public profileIdToPendingOwner;

    /// @notice Allo Owner Role for fund recovery
    bytes32 public constant ALLO_OWNER = keccak256("ALLO_OWNER");

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Checks if the caller is the profile owner
    /// @dev Reverts `UNAUTHORIZED()` if the caller is not the profile owner
    /// @param _profileId The ID of the profile
    modifier onlyProfileOwner(bytes32 _profileId) {
        _checkOnlyProfileOwner(_profileId);
        _;
    }

    // ====================================
    // =========== Initializer =============
    // ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> a higher version should be passed to reinitializer. Reverts if the '_owner' is the 'address(0)'
    /// @param _owner The owner of the contract
    function initialize(address _owner) external reinitializer(1) {
        // Make sure the owner is not 'address(0)'
        if (_owner == address(0)) revert ZERO_ADDRESS();

        // Grant the role to the owner
        _grantRole(ALLO_OWNER, _owner);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Retrieve profile by profileId
    /// @dev Used when you have the 'profileId' and want to retrieve the profile
    /// @param _profileId The ID of the profile
    /// @return The Profile details for the `_profileId`
    function getProfileById(bytes32 _profileId) external view returns (Profile memory) {
        return profilesById[_profileId];
    }

    /// @notice Retrieve profile by anchor
    /// @dev Used when you have the 'anchor' address and want to retrieve the profile
    /// @param _anchor The anchor of the profile
    /// @return Profile details for the `_anchor`
    function getProfileByAnchor(address _anchor) external view returns (Profile memory) {
        bytes32 profileId = anchorToProfileId[_anchor];
        return profilesById[profileId];
    }

    /// @notice Creates a new profile
    /// @dev This will also generate the 'profileId' and 'anchor' address, emits a 'ProfileCreated()' event
    /// Note: The 'nonce' is used to generate the 'profileId' and should be unique for each profile
    /// Note: The 'name' and 'profileId' are used to generate the 'anchor' address
    /// @param _nonce Nonce used to generate profileId. Can be any integer, but should be unique
    ///               for each profile.
    /// @param _name The name of the profile
    /// @param _metadata The metadata of the profile
    /// @param _owner The owner of the profile
    /// @param _members The members of the profile (can be set only if msg.sender == _owner)
    /// @return The ID for the created profile
    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32) {
        // Generate a profile ID using a nonce and the msg.sender
        bytes32 profileId = _generateProfileId(_nonce, _owner);

        // Make sure the nonce is available
        if (profilesById[profileId].anchor != address(0)) revert NONCE_NOT_AVAILABLE();

        // Make sure the owner is not the zero address
        if (_owner == address(0)) revert ZERO_ADDRESS();

        // Create a new Profile instance, also generates the anchor address
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

        // Assign roles for the profile members
        uint256 memberLength = _members.length;

        // Only profile owner can add members
        if (memberLength > 0 && _owner != msg.sender) {
            revert UNAUTHORIZED();
        }

        for (uint256 i; i < memberLength;) {
            address member = _members[i];

            // Will revert if any of the addresses are a zero address
            if (member == address(0)) revert ZERO_ADDRESS();

            // Grant the role to the member and emit the event for each member
            _grantRole(profileId, member);
            unchecked {
                ++i;
            }
        }

        // Emit the event that the profile was created
        emit ProfileCreated(profileId, profile.nonce, profile.name, profile.metadata, profile.owner, profile.anchor);

        // Return the profile ID
        return profileId;
    }

    /// @notice Updates the name of the profile and generates new anchor.
    ///         Emits a 'ProfileNameUpdated()' event.
    /// @dev Use caution when updating your profile name as it will generate a new anchor address. You can always update the name
    ///      back to the original name to get the original anchor address. 'msg.sender' must be the owner of the profile.
    /// @param _profileId The profileId of the profile
    /// @param _name The new name of the profile
    /// @return anchor The new anchor
    function updateProfileName(bytes32 _profileId, string memory _name)
        external
        onlyProfileOwner(_profileId)
        returns (address anchor)
    {
        // Generate a new anchor address
        anchor = _generateAnchor(_profileId, _name);

        // Get the profile using the profileId from the mapping
        Profile storage profile = profilesById[_profileId];

        // Set the new name
        profile.name = _name;

        // Remove old anchor
        anchorToProfileId[profile.anchor] = bytes32(0);

        // Set the new anchor
        profile.anchor = anchor;
        anchorToProfileId[anchor] = _profileId;

        // Emit the event that the name was updated with the new data
        emit ProfileNameUpdated(_profileId, _name, anchor);

        // Return the new anchor
        return anchor;
    }

    /// @notice Update the 'Metadata' of the profile. Emits a 'ProfileMetadataUpdated()' event.
    /// @dev 'msg.sender' must be the owner of the profile.
    /// @param _profileId The ID of the profile
    /// @param _metadata The new 'Metadata' of the profile
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata)
        external
        onlyProfileOwner(_profileId)
    {
        // Get the profile using the 'profileId' from the mapping and update the 'Metadata' value
        profilesById[_profileId].metadata = _metadata;

        // Emit the event that the 'Metadata' was updated
        emit ProfileMetadataUpdated(_profileId, _metadata);
    }

    /// @notice Checks if the address is an owner or member of the profile
    /// @param _profileId The ID of the profile
    /// @param _account The address to check
    /// @return 'true' if the address is an owner or member of the profile, otherwise 'false'
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool) {
        return _isOwnerOfProfile(_profileId, _account) || _isMemberOfProfile(_profileId, _account);
    }

    /// @notice Checks if the given address is an owner of the profile
    /// @param _profileId The ID of the profile
    /// @param _owner The address to check
    /// @return 'true' if the address is an owner of the profile, otherwise 'false'
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool) {
        return _isOwnerOfProfile(_profileId, _owner);
    }

    /// @notice Checks if the given address is a member of the profile
    /// @param _profileId The ID of the profile
    /// @param _member The address to check
    /// @return 'true' if the address is a member of the profile, otherwise 'false'
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool) {
        return _isMemberOfProfile(_profileId, _member);
    }

    /// @notice Updates the pending owner of the profile. Emits a 'ProfilePendingOwnership()' event.
    /// @dev 'msg.sender' must be the owner of the profile. [1]*This is step one of two when transferring ownership.
    /// @param _profileId The ID of the profile
    /// @param _pendingOwner The new pending owner
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner)
        external
        onlyProfileOwner(_profileId)
    {
        // Set the pending owner to the profile
        profileIdToPendingOwner[_profileId] = _pendingOwner;

        // Emit the event that the pending owner was updated
        emit ProfilePendingOwnerUpdated(_profileId, _pendingOwner);
    }

    /// @notice Transfers the ownership of the profile to the pending owner and Emits a 'ProfileOwnerUdpated()' event.
    /// @dev 'msg.sender' must be the pending owner of the profile. [2]*This is step two of two when transferring ownership.
    /// @param _profileId The ID of the profile
    function acceptProfileOwnership(bytes32 _profileId) external {
        // Get the profile from the mapping
        Profile storage profile = profilesById[_profileId];

        // Get the pending owner from the mapping that was set when the owner was updated
        address newOwner = profileIdToPendingOwner[_profileId];

        // Revert if the 'msg.sender' is not the pending owner
        if (msg.sender != newOwner) revert NOT_PENDING_OWNER();

        // Set the new owner and delete the pending owner from the mapping
        profile.owner = newOwner;
        delete profileIdToPendingOwner[_profileId];

        // Emit the event that the owner was accepted and updated
        emit ProfileOwnerUpdated(_profileId, profile.owner);
    }

    /// @notice Adds members to the profile
    /// @dev 'msg.sender' must be the owner of the profile.
    /// @param _profileId The ID of the profile
    /// @param _members The members to add
    function addMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        // Loop through the members and add them to the profile by granting the role
        for (uint256 i; i < memberLength;) {
            address member = _members[i];

            // Will revert if any of the addresses are a zero address
            if (member == address(0)) revert ZERO_ADDRESS();

            // Grant the role to the member and emit the event for each member
            _grantRole(_profileId, member);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes members from the profile
    /// @dev 'msg.sender' must be the pending owner of the profile.
    /// @param _profileId The ID of the profile
    /// @param _members The members to remove
    function removeMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        // Loop through the members and remove them from the profile by revoking the role
        for (uint256 i; i < memberLength;) {
            // Revoke the role from the member and emit the event for each member
            _revokeRole(_profileId, _members[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// ====================================
    /// ======== Internal Functions ========
    /// ====================================

    /// @notice Checks if the caller is the owner of the profile
    /// @dev Internal function used by modifier 'onlyProfileOwner'
    /// @param _profileId The ID of the profile
    function _checkOnlyProfileOwner(bytes32 _profileId) internal view {
        if (!_isOwnerOfProfile(_profileId, msg.sender)) revert UNAUTHORIZED();
    }

    /// @notice Generates and deploys the anchor for the given 'profileId' and name
    /// @dev Internal function used by 'createProfile()' and 'updateProfileName()' to create and anchor.
    /// @param _profileId The ID of the profile
    /// @param _name The name of the profile
    /// @return anchor The address of the deployed anchor contract
    function _generateAnchor(bytes32 _profileId, string memory _name) internal returns (address anchor) {
        bytes memory encodedData = abi.encode(_profileId, _name);
        bytes memory encodedConstructorArgs = abi.encode(_profileId, address(this));

        bytes memory bytecode = abi.encodePacked(type(Anchor).creationCode, encodedConstructorArgs);

        bytes32 salt = keccak256(encodedData);

        address preComputedAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)))))
        );

        // Try to deploy the anchor contract, if it fails then the anchor already exists
        try new Anchor{salt: salt}(_profileId, address(this)) returns (Anchor _anchor) {
            anchor = address(_anchor);
        } catch {
            if (Anchor(payable(preComputedAddress)).profileId() != _profileId) revert ANCHOR_ERROR();
            anchor = preComputedAddress;
        }
    }

    /// @notice Generates the 'profileId' based on msg.sender and nonce
    /// @dev Internal function used by 'createProfile()' to generate profileId.
    /// @param _nonce Nonce provided by the caller to generate 'profileId'
    /// @param _owner The owner of the profile
    /// @return 'profileId' The ID of the profile
    function _generateProfileId(uint256 _nonce, address _owner) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, _owner));
    }

    /// @notice Checks if an address is the owner of the profile
    /// @dev Internal function used to determine if an address is the profile owner
    /// @param _profileId The 'profileId' of the profile
    /// @param _owner The address to check
    /// @return 'true' if the address is an owner of the profile, otherwise 'false'
    function _isOwnerOfProfile(bytes32 _profileId, address _owner) internal view returns (bool) {
        return profilesById[_profileId].owner == _owner;
    }

    /// @notice Checks if an address is a member of the profile
    /// @dev Internal function used to determine if an address is a member of the profile
    /// @param _profileId The 'profileId' of the profile
    /// @param _member The address to check
    /// @return 'true' if the address is a member of the profile, otherwise 'false'
    function _isMemberOfProfile(bytes32 _profileId, address _member) internal view returns (bool) {
        return hasRole(_profileId, _member);
    }

    /// @notice Transfers any fund balance in Allo to the recipient
    /// @dev 'msg.sender' must be the Allo owner
    /// @param _token The address of the token to transfer
    /// @param _recipient The address of the recipient
    function recoverFunds(address _token, address _recipient) external onlyRole(ALLO_OWNER) {
        if (_recipient == address(0)) revert ZERO_ADDRESS();

        uint256 amount = _token == NATIVE ? address(this).balance : ERC20(_token).balanceOf(address(this));
        _transferAmount(_token, _recipient, amount);
    }
}
