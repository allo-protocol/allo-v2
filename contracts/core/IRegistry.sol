// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Internal Libraries
import {Metadata} from "./libraries/Metadata.sol";

/**
 * @title IRegistry Contract
 *
 * The Registry contract is used to store and manage all the profiles that are created within the Allo protocol
 *
 * @author allo-team
 * @notice Interface for the Registry contract and exposes all functions needed to use the Registry
 *         within the Allo protocol
 *
 */
interface IRegistry {
    /// ======================
    /// ======= Structs ======
    /// ======================

    /**
     * @dev The Profile struct that all profiles are based from
     */
    struct Profile {
        bytes32 id;
        uint256 nonce;
        string name;
        Metadata metadata;
        address owner;
        address anchor;
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    /**
     * @dev Returned when the nonce passed has been used or not available
     */
    error NONCE_NOT_AVAILABLE();

    /**
     * @dev Returned when the 'msg.sender' is not the pending owner on ownership transfer
     */
    error NOT_PENDING_OWNER();

    /**
     * @dev Returned when the 'msg.sender' is not authorized
     */
    error UNAUTHORIZED();

    /**
     * @dev Returned if any address check is the zero address
     */
    error ZERO_ADDRESS();

    /// ======================
    /// ======= Events =======
    /// ======================

    /**
     * @dev Event emitted when a profile is created
     *
     * Note: This will return your anchor address
     *
     */
    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    /**
     * @dev Event emitted when a profile name is updated
     *
     * Note: This will update the anchor when the name is updated and return it
     *
     */
    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);

    /**
     * @dev Event emitted when a profile's metadata is updated
     */
    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);

    /**
     * @dev Event emitted when a profile owner is updated
     */
    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);

    /**
     * @dev Event emitted when a profile pending owner is updated
     */
    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /**
     * @dev Returns the 'Profile' for a '_profileId' passed
     */
    function getProfileById(bytes32 _profileId) external view returns (Profile memory);

    /**
     * @dev Returns the 'Profile' for an '_anchor' passed
     */
    function getProfileByAnchor(address _anchor) external view returns (Profile memory);

    /**
     * @dev Returns a boolean if the '_account' is a member or owner of the '_profileId' passed in
     */
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool);

    /**
     * @dev Returns a boolean if the '_account' is an owner of the '_profileId' passed in
     */
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool);

    /**
     * @dev Returns a boolean if the '_account' is a member of the '_profileId' passed in
     */
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /**
     * @dev Creates a new 'Profile' and returns the 'profileId' of the new profile
     *
     * Note: The 'name' and 'nonce' are used to generate the 'anchor' address
     *
     * Requirements: None, anyone can create a new profile
     *
     *
     */
    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32);

    /**
     * @dev Updates the 'name' of the '_profileId' passed in and returns the new 'anchor' address
     *
     * Requirements: Only the 'Profile' owner can update the name
     *
     * Note: The 'name' and 'nonce' are used to generate the 'anchor' address and this will update the 'anchor'
     *       so please use caution. You can always recreate your 'anchor' address by updating the name back
     *       to the original name used to create the profile.
     *
     */
    function updateProfileName(bytes32 _profileId, string memory _name) external returns (address);

    /**
     * @dev Updates the 'metadata' of the '_profileId' passed in
     *
     * Requirements: Only the 'Profile' owner can update the metadata
     *
     */
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata) external;

    /**
     * @dev Updates the pending 'owner' of the '_profileId' passed in
     *
     * Requirements: Only the 'Profile' owner can update the pending owner
     *
     */
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external;

    /**
     * @dev Accepts the pending 'owner' of the '_profileId' passed in
     *
     * Requirements: Only the pending owner can accept the ownership
     *
     */
    function acceptProfileOwnership(bytes32 _profileId) external;

    /**
     * @dev Adds members to the '_profileId' passed in
     *
     * Requirements: Only the 'Profile' owner can add members
     *
     */
    function addMembers(bytes32 _profileId, address[] memory _members) external;

    /**
     * @dev Removes members from the '_profileId' passed in
     *
     * Requirements: Only the 'Profile' owner can remove members
     *
     */
    function removeMembers(bytes32 _profileId, address[] memory _members) external;

    /**
     * @dev Recovers funds from the contract
     *
     * Requirements: Must be the Allo owner
     *
     */
    function recoverFunds(address _token, address _recipient) external;
}
