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

    event IdentityCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );
    event IdentityNameUpdated(bytes32 indexed profileId, string name, address anchor);
    event IdentityMetadataUpdated(bytes32 indexed profileId, Metadata metadata);
    event IdentityOwnerUpdated(bytes32 indexed profileId, address owner);
    event IdentityPendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    function getIdentityById(bytes32 profileId) external view returns (Profile memory);
    function getIdentityByAnchor(address _anchor) external view returns (Profile memory);
    function isOwnerOrMemberOfIdentity(bytes32 _profileId, address _account) external view returns (bool);
    function isOwnerOfIdentity(bytes32 _profileId, address _owner) external view returns (bool);
    function isMemberOfIdentity(bytes32 _profileId, address _member) external view returns (bool);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    function createIdentity(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32);
    function updateIdentityName(bytes32 _profileId, string memory _name) external returns (address);
    function updateIdentityMetadata(bytes32 _profileId, Metadata memory _metadata) external;
    function updateIdentityPendingOwner(bytes32 _profileId, address _pendingOwner) external;
    function acceptIdentityOwnership(bytes32 _profileId) external;
    function addMembers(bytes32 _profileId, address[] memory _members) external;
    function removeMembers(bytes32 _profileId, address[] memory _members) external;
    function recoverFunds(address _token, address _recipient) external;
}
