// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Metadata} from "./libraries/Metadata.sol";

interface IRegistry {
    /// ======================
    /// ======= Structs ======
    /// ======================

    struct Identity {
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
        bytes32 indexed identityId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );
    event IdentityNameUpdated(bytes32 indexed identityId, string name, address anchor);
    event IdentityMetadataUpdated(bytes32 indexed identityId, Metadata metadata);
    event IdentityOwnerUpdated(bytes32 indexed identityId, address owner);
    event IdentityPendingOwnerUpdated(bytes32 indexed identityId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    function getIdentityById(bytes32 identityId) external view returns (Identity memory);
    function getIdentityByAnchor(address _anchor) external view returns (Identity memory);
    function isOwnerOrMemberOfIdentity(bytes32 _identityId, address _account) external view returns (bool);
    function isOwnerOfIdentity(bytes32 _identityId, address _owner) external view returns (bool);
    function isMemberOfIdentity(bytes32 _identityId, address _member) external view returns (bool);

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
    function updateIdentityName(bytes32 _identityId, string memory _name) external returns (address);
    function updateIdentityMetadata(bytes32 _identityId, Metadata memory _metadata) external;
    function updateIdentityPendingOwner(bytes32 _identityId, address _pendingOwner) external;
    function acceptIdentityOwnership(bytes32 _identityId) external;
    function addMembers(bytes32 _identityId, address[] memory _members) external;
    function removeMembers(bytes32 _identityId, address[] memory _members) external;
    function recoverFunds(address _token, address _recipient) external;
}
