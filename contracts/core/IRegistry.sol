// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Internal Libraries
import {Metadata} from "./libraries/Metadata.sol";

interface IRegistry {
    /// ======================
    /// ======= Structs ======
    /// ======================

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
    error NONCE_NOT_AVAILABLE();
    error NOT_PENDING_OWNER();
    error UNAUTHORIZED();
    error ZERO_ADDRESS();

    /// ======================
    /// ======= Events =======
    /// ======================

    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );
    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);
    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);
    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);
    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    function getProfileById(bytes32 profileId) external view returns (Profile memory);
    function getProfileByAnchor(address _anchor) external view returns (Profile memory);
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool);
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool);
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32);
    function updateProfileName(bytes32 _profileId, string memory _name) external returns (address);
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata) external;
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external;
    function acceptProfileOwnership(bytes32 _profileId) external;
    function addMembers(bytes32 _profileId, address[] memory _members) external;
    function removeMembers(bytes32 _profileId, address[] memory _members) external;
    function recoverFunds(address _token, address _recipient) external;
}
