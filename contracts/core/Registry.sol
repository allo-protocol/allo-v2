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
/// @notice Registry contract for identities
/// @dev This contract is used to create and manage identities
/// @author allo-team
contract Registry is IRegistry, Native, AccessControl, Transfer {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice anchor -> Identity.id
    mapping(address => bytes32) public anchorToIdentityId;

    /// @notice Identity.id -> Identity
    mapping(bytes32 => Identity) public identitiesById;

    /// @notice Identity.id -> pending owner
    mapping(bytes32 => address) public identityIdToPendingOwner;

    /// @notice Allo Owner Role for fund recovery
    bytes32 public constant ALLO_OWNER = keccak256("ALLO_OWNER");

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the owner of the identity
    modifier onlyIdentityOwner(bytes32 _identityId) {
        if (!isOwnerOfIdentity(_identityId, msg.sender)) {
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

    /// @notice Retrieve identity by identityId
    /// @param identityId The identityId of the identity
    function getIdentityById(bytes32 identityId) public view returns (Identity memory) {
        return identitiesById[identityId];
    }

    /// @notice Retrieve identity by anchor
    /// @param _anchor The anchor of the identity
    function getIdentityByAnchor(address _anchor) public view returns (Identity memory) {
        bytes32 identityId = anchorToIdentityId[_anchor];
        return identitiesById[identityId];
    }

    /// @notice Creates a new identity
    /// @dev This will also set the attestation address generated from msg.sender and name
    /// @param _nonce Nonce used to generate identityId
    /// @param _name The name of the identity
    /// @param _metadata The metadata of the identity
    /// @param _members The members of the identity
    /// @param _owner The owner of the identity
    function createIdentity(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32) {
        bytes32 identityId = _generateIdentityId(_nonce);

        if (identitiesById[identityId].anchor != address(0)) {
            revert NONCE_NOT_AVAILABLE();
        }

        if (_owner == address(0)) {
            revert ZERO_ADDRESS();
        }

        Identity memory identity = Identity({
            id: identityId,
            nonce: _nonce,
            name: _name,
            metadata: _metadata,
            owner: _owner,
            anchor: _generateAnchor(identityId, _name)
        });

        identitiesById[identityId] = identity;
        anchorToIdentityId[identity.anchor] = identityId;

        // assign roles
        uint256 memberLength = _members.length;
        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }
            _grantRole(identityId, member);
            unchecked {
                i++;
            }
        }

        emit IdentityCreated(
            identityId, identity.nonce, identity.name, identity.metadata, identity.owner, identity.anchor
        );

        return identityId;
    }

    /// @notice Updates the name of the identity and generates new anchor
    /// @param _identityId The identityId of the identity
    /// @param _name The new name of the identity
    /// @dev Only owner can update the name.
    function updateIdentityName(bytes32 _identityId, string memory _name)
        external
        onlyIdentityOwner(_identityId)
        returns (address)
    {
        address anchor = _generateAnchor(_identityId, _name);

        Identity storage identity = identitiesById[_identityId];
        identity.name = _name;

        // remove old anchor
        anchorToIdentityId[identity.anchor] = bytes32(0);

        // set new anchor
        identity.anchor = anchor;
        anchorToIdentityId[anchor] = _identityId;

        emit IdentityNameUpdated(_identityId, _name, anchor);

        // TODO: should we return identity
        return anchor;
    }

    /// @notice update the metadata of the identity
    /// @param _identityId The identityId of the identity
    /// @param _metadata The new metadata of the identity
    /// @dev Only owner can update metadata
    function updateIdentityMetadata(bytes32 _identityId, Metadata memory _metadata)
        external
        onlyIdentityOwner(_identityId)
    {
        identitiesById[_identityId].metadata = _metadata;

        emit IdentityMetadataUpdated(_identityId, _metadata);
    }

    /// @notice Returns if the given address is an owner or member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _account The address to check
    function isOwnerOrMemberOfIdentity(bytes32 _identityId, address _account) public view returns (bool) {
        return isOwnerOfIdentity(_identityId, _account) || isMemberOfIdentity(_identityId, _account);
    }

    /// @notice Returns if the given address is an owner of the identity
    /// @param _identityId The identityId of the identity
    /// @param _owner The address to check
    function isOwnerOfIdentity(bytes32 _identityId, address _owner) public view returns (bool) {
        return identitiesById[_identityId].owner == _owner;
    }

    /// @notice Returns if the given address is an member of the identity
    /// @param _identityId The identityId of the identity
    /// @param _member The address to check
    function isMemberOfIdentity(bytes32 _identityId, address _member) public view returns (bool) {
        return hasRole(_identityId, _member);
    }

    /// @notice Updates the pending owner of the identity
    /// @param _identityId The identityId of the identity
    /// @param _pendingOwner New pending owner
    function updateIdentityPendingOwner(bytes32 _identityId, address _pendingOwner)
        external
        onlyIdentityOwner(_identityId)
    {
        identityIdToPendingOwner[_identityId] = _pendingOwner;

        emit IdentityPendingOwnerUpdated(_identityId, _pendingOwner);
    }

    /// @notice Transfers the ownership of the identity to the pending owner
    /// @param _identityId The identityId of the identity
    /// @dev Only pending owner can claim ownership.
    function acceptIdentityOwnership(bytes32 _identityId) external {
        Identity storage identity = identitiesById[_identityId];
        address newOwner = identityIdToPendingOwner[_identityId];

        if (msg.sender != newOwner) {
            revert NOT_PENDING_OWNER();
        }

        identity.owner = newOwner;
        delete identityIdToPendingOwner[_identityId];

        emit IdentityOwnerUpdated(_identityId, identity.owner);
    }

    /// @notice Adds members to the identity
    /// @param _identityId The identityId of the identity
    /// @param _members The members to add
    /// @dev Only owner can add members
    function addMembers(bytes32 _identityId, address[] memory _members) external onlyIdentityOwner(_identityId) {
        uint256 memberLength = _members.length;

        for (uint256 i = 0; i < memberLength;) {
            address member = _members[i];
            if (member == address(0)) {
                revert ZERO_ADDRESS();
            }
            _grantRole(_identityId, member);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Removes members from the identity
    /// @param _identityId The identityId of the identity
    /// @param _members The members to remove
    /// @dev Only owner can remove members
    function removeMembers(bytes32 _identityId, address[] memory _members) external onlyIdentityOwner(_identityId) {
        uint256 memberLength = _members.length;

        for (uint256 i = 0; i < memberLength;) {
            _revokeRole(_identityId, _members[i]);
            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ======== Internal Functions ========
    /// ====================================

    /// @notice Generates and deploy the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _generateAnchor(bytes32 _identityId, string memory _name) internal returns (address anchor) {
        bytes32 salt = keccak256(abi.encodePacked(_identityId, _name));

        bytes memory creationCode = abi.encodePacked(type(Anchor).creationCode, abi.encode(_identityId));

        anchor = CREATE3.deploy(salt, creationCode, 0);
    }

    /// @notice Generates the identityId based on msg.sender
    /// @param _nonce Nonce used to generate identityId
    function _generateIdentityId(uint256 _nonce) internal view returns (bytes32) {
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
