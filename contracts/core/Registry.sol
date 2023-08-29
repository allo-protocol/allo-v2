// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// External Libraries
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {CREATE3} from "solady/src/utils/CREATE3.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
// Interfaces
import "./interfaces/IRegistry.sol";
// Internal Libraries
import {Anchor} from "./Anchor.sol";
import {Metadata} from "./libraries/Metadata.sol";
import "./libraries/Native.sol";
import "./libraries/Transfer.sol";

/// @title Registry Contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, 
///         @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Registry contract for creating and managing profiles
/// @dev This contract is used to create and manage profiles for the Allo protocol
///      It is also used to deploy the anchor contract for each profile which acts as a proxy
///      for the profile and is used to receive funds and execute transactions on behalf of the profile
///      The Registry is also used to add and remove members from a profile and update the profile 'Metadata'
contract Registry is IRegistry, Native, AccessControl, Transfer, Initializable {
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
        if (!_isOwnerOfProfile(_profileId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    // ====================================
    // =========== Initializer =============
    // ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> an higher version should be passed to reinitializer
    /// @param _owner The owner of the contract
    /// @dev Reverts if the '_owner' is the 'address(0)'
    function initialize(address _owner) external reinitializer(1) {
        // Make sure the owner is not 'address(0)'
        if (_owner == address(0)) {
            revert ZERO_ADDRESS();
        }

        // Grant the role to the owner
        _grantRole(ALLO_OWNER, _owner);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Retrieve profile by profileId
    /// @dev This can be used when you have the 'profileId' and want to retrieve the profile
    ///
    /// @param _profileId The profileId of the profile
    ///
    /// @return Profile The profile for the profileId
    function getProfileById(bytes32 _profileId) external view returns (Profile memory) {
        return profilesById[_profileId];
    }

    /// @notice Retrieve profile by anchor
    /// @dev This can be used when you have the 'anchor' address and want to retrieve the profile
    /// @param _anchor The anchor of the profile
    ///
    /// @return Profile The profile for the anchor passed
    function getProfileByAnchor(address _anchor) external view returns (Profile memory) {
        bytes32 profileId = anchorToProfileId[_anchor];
        return profilesById[profileId];
    }

    /// @notice Creates a new profile
    /// @dev This will also generate the 'profileId' and 'anchor' address, emits a {ProfileCreated} event
    ///
    /// Note: The 'nonce' is used to generate the 'profileId' and should be unique for each profile
    /// Note: The 'name' and 'profileId' are used to generate the 'anchor' address
    ///
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
        // Generate a profile id using a nonce and the msg.sender
        bytes32 profileId = _generateProfileId(_nonce);

        // Make sure the nonce is available
        if (profilesById[profileId].anchor != address(0)) {
            revert NONCE_NOT_AVAILABLE();
        }

        // Make sure the owner is not the zero address
        if (_owner == address(0)) {
            revert ZERO_ADDRESS();
        }

        // Create a new Profile instance
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
        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];

            // Will revert if any of the addresses are a zero address
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }

            // Grant the role to the member and emit the event for each member
            _grantRole(profileId, member);
            unchecked {
                i++;
            }
        }

        // Emit the event that the profile was created
        emit ProfileCreated(profileId, profile.nonce, profile.name, profile.metadata, profile.owner, profile.anchor);

        // Return the profileId
        return profileId;
    }

    /// @notice Updates the name of the profile and generates new anchor
    ///
    /// Requirements: 'msg.sender' must be the owner of the profile
    ///
    /// Note: Use caution when updating your profile name as it will generate a new anchor address
    /// Note: You can always update the name back to the original name to get the original anchor address
    ///
    /// @param _profileId The profileId of the profile
    /// @param _name The new name of the profile
    /// @dev Only owner can update the name
    function updateProfileName(bytes32 _profileId, string memory _name)
        external
        onlyProfileOwner(_profileId)
        returns (address)
    {
        // Generate a new anchor address
        address anchor = _generateAnchor(_profileId, _name);

        // Get the profile using the profileId from the mapping
        Profile storage profile = profilesById[_profileId];

        // Set the new name
        profile.name = _name;

        // Remove old anchor
        anchorToProfileId[profile.anchor] = bytes32(0);

        // Set new anchor
        profile.anchor = anchor;
        anchorToProfileId[anchor] = _profileId;

        // Emit the event that the name was updated
        emit ProfileNameUpdated(_profileId, _name, anchor);

        // Return the new anchor address
        return anchor;
    }

    /// @notice Update the 'Metadata' of the profile
    ///
    /// Requirements: 'msg.sender' must be the owner of the profile to update the 'Metadata'
    ///
    /// @param _profileId The 'profileId' of the profile
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

    /// @notice Returns if the given address is an owner or member of the profile
    /// @param _profileId The 'profileId' of the profile
    /// @param _account The address to check
    ///
    /// @return bool Returns true if the address is an owner or member of the profile
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool) {
        return _isOwnerOfProfile(_profileId, _account) || _isMemberOfProfile(_profileId, _account);
    }

    /// @notice Returns if the given address is an owner of the profile
    /// @param _profileId The 'profileId' of the profile
    /// @param _owner The address to check
    ///
    /// @return bool Returns true if the address is an owner of the profile
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool) {
        return _isOwnerOfProfile(_profileId, _owner);
    }

    /// @notice Returns if the given address is an member of the profile
    /// @param _profileId The 'profileId' of the profile
    /// @param _member The address to check
    ///
    /// @return bool Returns true if the address is an member of the profile
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool) {
        return _isMemberOfProfile(_profileId, _member);
    }

    /// @notice Updates the pending owner of the profile
    /// @dev This is used to transfer ownership of the profile to a new owner
    ///
    /// Requirements: Must be the owner of the profile to update the owner
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @param _pendingOwner New pending owner
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner)
        external
        onlyProfileOwner(_profileId)
    {
        // Set the pending owner to the profile
        profileIdToPendingOwner[_profileId] = _pendingOwner;

        // Emit the event that the pending owner was updated
        emit ProfilePendingOwnerUpdated(_profileId, _pendingOwner);
    }

    /// @notice Transfers the ownership of the profile to the pending owner
    ///
    /// Requirements: Must be the pending owner of the profile to accept ownership
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @dev Only pending owner can claim ownership
    function acceptProfileOwnership(bytes32 _profileId) external {
        // Get the profile from the mapping
        Profile storage profile = profilesById[_profileId];

        // Get the pending owner from the mapping that was set when the owner was updated
        address newOwner = profileIdToPendingOwner[_profileId];

        // Revert if the 'msg.sender' is not the pending owner
        if (msg.sender != newOwner) {
            revert NOT_PENDING_OWNER();
        }

        // Set the new owner and delete the pending owner from the mapping
        profile.owner = newOwner;
        delete profileIdToPendingOwner[_profileId];

        // Emit the event that the owner was accepted and updated
        emit ProfileOwnerUpdated(_profileId, profile.owner);
    }

    /// @notice Adds members to the profile
    ///
    /// Requirements: Must be the owner of the profile to add members
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @param _members The members to add
    function addMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        // Loop through the members and add them to the profile by granting the role
        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];

            // Will revert if any of the addresses are a zero address
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }

            // Grant the role to the member and emit the event for each member
            _grantRole(_profileId, member);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Removes members from the profile
    ///
    /// Requirements: Must be the owner of the profile to remove members
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @param _members The members to remove
    function removeMembers(bytes32 _profileId, address[] memory _members) external onlyProfileOwner(_profileId) {
        uint256 memberLength = _members.length;

        // Loop through the members and remove them from the profile by revoking the role
        for (uint256 i = 0; i < memberLength;) {
            // Revoke the role from the member and emit the event for each member
            _revokeRole(_profileId, _members[i]);
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ======== Internal Functions ========
    /// ====================================

    /// @dev Generates and deploys the anchor for the given 'profileId' and name
    ///
    /// @param _profileId Id of the profile
    /// @param _name The name of the profile
    ///
    /// @return anchor The address of the deployed anchor contract
    function _generateAnchor(bytes32 _profileId, string memory _name) internal returns (address anchor) {
        bytes32 salt = keccak256(abi.encodePacked(_profileId, _name));

        address preCalculatedAddress = CREATE3.getDeployed(salt);

        // check if the contract already exists and if the profileId matches
        if (preCalculatedAddress.code.length > 0) {
            if (Anchor(payable(preCalculatedAddress)).profileId() != _profileId) {
                revert ANCHOR_ERROR();
            }
            anchor = preCalculatedAddress;
        } else {
            // check if the contract has already been deployed by checking code size of address
            bytes memory creationCode = abi.encodePacked(type(Anchor).creationCode, abi.encode(_profileId));

            // Use CREATE3 to deploy the anchor contract
            anchor = CREATE3.deploy(salt, creationCode, 0);
        }
    }

    /// @dev Generates the 'profileId' based on msg.sender
    ///
    /// @param _nonce Nonce used to generate 'profileId'
    ///
    /// @return 'profileId' The 'profileId' of the profile
    function _generateProfileId(uint256 _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, msg.sender));
    }

    /// @dev Returns if the given address is an owner of the profile
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @param _owner The address to check
    ///
    /// @return bool Returns true if the address is an owner of the profile
    function _isOwnerOfProfile(bytes32 _profileId, address _owner) internal view returns (bool) {
        return profilesById[_profileId].owner == _owner;
    }

    /// @dev Returns if the given address is an member of the profile
    ///
    /// @param _profileId The 'profileId' of the profile
    /// @param _member The address to check
    ///
    /// @return bool Returns true if the address is an member of the profile
    function _isMemberOfProfile(bytes32 _profileId, address _member) internal view returns (bool) {
        return hasRole(_profileId, _member);
    }

    /// @dev Transfer thefunds recovered  to the recipient
    ///
    /// @param _token The address of the token to transfer
    /// @param _recipient The address of the recipient
    ///
    /// Requirements: Only the Allo owner can recover funds
    ///
    function recoverFunds(address _token, address _recipient) external onlyRole(ALLO_OWNER) {
        if (_recipient == address(0)) {
            revert ZERO_ADDRESS();
        }
        uint256 amount = _token == NATIVE ? address(this).balance : ERC20(_token).balanceOf(address(this));
        _transferAmount(_token, _recipient, amount);
    }
}
