// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {QVSimpleStrategy} from "../qv-simple/QVSimpleStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

import {ERC721} from "@solady/tokens/ERC721.sol";

// Note: EAS Contracts
import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    RevocationRequest,
    RevocationRequestData
} from "@ethereum-attestation-service/IEAS.sol";
import {ISchemaRegistry, ISchemaResolver, SchemaRecord} from "@ethereum-attestation-service/ISchemaRegistry.sol";
import {SchemaResolver} from "./SchemaResolver.sol";

// Register the schema with the SchemaRegistry contract when required.
// https://optimism-goerli.easscan.org/schema/create
// https://docs.attest.sh/docs/tutorials/create-a-schema
// https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/

contract HackathonQVStrategy is QVSimpleStrategy, SchemaResolver {
    struct EASInfo {
        IEAS eas;
        ISchemaRegistry schemaRegistry;
        bytes32 schemaUID;
        string schema;
        bool revocable;
    }

    /// ======================
    /// ==== Custom Error ====
    /// ======================

    error ALREADY_ADDED();
    error OUT_OF_BOUNDS();
    error INVALID_SCHEMA();

    /// ======================
    /// ====== Storage =======
    /// ======================

    bytes32 constant _NO_RELATED_ATTESTATION_UID = 0;
    ISchemaRegistry public schemaRegistry;
    EASInfo public easInfo;
    ERC721 public nft;

    // recipientId -> uid
    mapping(address => bytes32) public attestations;
    // nftId -> voiceCreditsUsed
    mapping(uint256 => uint256) public voiceCreditsUsedPerNftId;

    /// ======================
    /// ===== Constructor ====
    /// ======================

    constructor(address _allo, string memory _name) QVSimpleStrategy(_allo, _name) {}

    /// ======================
    /// ====== Initialize ====
    /// ======================

    /// @dev Initializes the strategy
    /// @param _poolId The pool ID for this strategy
    /// @param _data The data to initialize the strategy with
    function initialize(uint256 _poolId, bytes memory _data) public override {
        (EASInfo memory _easInfo, address _nft, bytes memory _qvSimpleInitData) =
            abi.decode(_data, (EASInfo, address, bytes));

        __HackathonQVStrategy_init(_poolId, _easInfo, _nft, _qvSimpleInitData);
    }

    /// @dev Initializes the strategy.
    // @solhint disable-next-line func-name-mixedcase
    function __HackathonQVStrategy_init(uint256 _poolId, EASInfo memory _easInfo, address _nft, bytes memory _data)
        internal
    {
        (
            metadataRequired,
            maxVoiceCreditsPerAllocator,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime
        ) = abi.decode(_data, (bool, uint256, uint256, uint256, uint256, uint256));

        __QVSimpleStrategy_init(
            _poolId,
            true, // useRegistryAnchor
            metadataRequired,
            maxVoiceCreditsPerAllocator,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime
        );

        __SchemaResolver_init(_easInfo.eas);

        easInfo = EASInfo({
            eas: _easInfo.eas,
            schemaRegistry: _easInfo.schemaRegistry,
            schema: _easInfo.schema,
            schemaUID: _easInfo.schemaUID,
            revocable: _easInfo.revocable
        });

        nft = ERC721(_nft);

        // register / validate SchemaRecord
        if (bytes(_easInfo.schema).length > 0) {
            // if the schema is present, then register schema and update uid
            easInfo.schemaUID =
                schemaRegistry.register(_easInfo.schema, ISchemaResolver(address(this)), _easInfo.revocable);
        } else {
            // compare SchemaRecord to data passed in
            SchemaRecord memory record = schemaRegistry.getSchema(_easInfo.schemaUID);
            if (
                record.uid != _easInfo.schemaUID || record.revocable != _easInfo.revocable
                    || keccak256(abi.encode(record.schema)) != keccak256(abi.encode(_easInfo.schema))
            ) {
                revert INVALID_SCHEMA();
            }
        }
    }

    /// ======================
    /// ====== External ======
    /// ======================

    /// Set the allowed recipient IDs
    /// @param _recipientIds The recipient IDs to allow
    /// @param _expirationTime The expiration time of the attestation
    /// @param _data The data to include in the attestation
    function setAllowedRecipientIds(address[] memory _recipientIds, uint64 _expirationTime, bytes memory _data)
        external
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            if (attestations[recipientId] != 0) {
                revert ALREADY_ADDED();
            }

            attestations[recipientId] = _grantEASAttestation(_recipientIds[i], _expirationTime, _data, 0);

            unchecked {
                i++;
            }
        }
    }

    /// =========================
    /// == Internal Functions ===
    /// =========================

    /// @notice Submit application to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        Metadata memory metadata;

        (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

        if (attestations[recipientId] == 0 || !_isIdentityMember(recipientId, _sender)) {
            revert UNAUTHORIZED();
        }

        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        Recipient storage recipient = recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = true;

        if (recipient.recipientStatus == InternalRecipientStatus.Rejected) {
            recipient.recipientStatus = InternalRecipientStatus.Appealed;
            emit Appealed(recipientId, _data, _sender);
        } else {
            recipient.recipientStatus = InternalRecipientStatus.Pending;
            emit Registered(recipientId, _data, _sender);
        }
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override {
        (address recipientId, uint256 nftId, uint256 voiceCreditsToAllocate) =
            abi.decode(_data, (address, uint256, uint256));

        // check that the sender can allocate votes
        if (nft.ownerOf(nftId) != _sender) {
            revert UNAUTHORIZED();
        }

        if (voiceCreditsToAllocate == 0) {
            revert INVALID();
        }

        // check the time periods for allocation
        if (block.timestamp < allocationStartTime || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (voiceCreditsToAllocate + voiceCreditsUsedPerNftId[nftId] > maxVoiceCreditsPerAllocator) {
            revert INVALID();
        }

        uint256 creditsCastToRecipient = allocator.voiceCreditsCastToRecipient[recipientId];
        uint256 votesCastToRecipient = allocator.votesCastToRecipient[recipientId];

        uint256 totalCredits = voiceCreditsToAllocate + creditsCastToRecipient;
        uint256 voteResult = _calculateVotes(totalCredits * 1e18);
        voteResult -= votesCastToRecipient;
        totalRecipientVotes += voteResult;
        recipient.totalVotes += voteResult;

        allocator.voiceCreditsCastToRecipient[recipientId] += totalCredits;
        allocator.votesCastToRecipient[recipientId] += voteResult;

        voiceCreditsUsedPerNftId[nftId] += voiceCreditsToAllocate;

        emit Allocated(_sender, voteResult, address(0), msg.sender);
    }

    /// @dev Grant EAS attestation to recipient with the EAS contract.
    /// @param _recipientId The recipient ID to grant the attestation to.
    /// @param _expirationTime The expiration time of the attestation.
    /// @param _data The data to include in the attestation.
    /// @param _value The value to send with the attestation.
    function _grantEASAttestation(address _recipientId, uint64 _expirationTime, bytes memory _data, uint256 _value)
        internal
        returns (bytes32)
    {
        AttestationRequest memory attestationRequest = AttestationRequest(
            easInfo.schemaUID,
            AttestationRequestData({
                recipient: _recipientId,
                expirationTime: _expirationTime,
                revocable: easInfo.revocable,
                refUID: _NO_RELATED_ATTESTATION_UID,
                data: _data,
                value: _value
            })
        );

        return easInfo.eas.attest(attestationRequest);
    }

    /// =========================
    /// ==== EAS Functions =====
    /// =========================

    // Note: EAS Information - Supported Testnets
    // Version: 0.27
    // * OP Goerli
    //    EAS Contract: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
    //    Schema Registry: 0x0a7E2Ff54e76B8E6659aedc9103FB21c038050D0
    // * Sepolia
    //    EAS Contract: 0x1a5650d0ecbca349dd84bafa85790e3e6955eb84
    //    Schema Registry: 0x7b24C7f8AF365B4E308b6acb0A7dfc85d034Cb3f

    /// @dev Gets an attestation from the EAS contract using the UID
    /// @param uid The UUID of the attestation to get.
    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        return easInfo.eas.getAttestation(uid);
    }

    /// @dev Gets a schema from the SchemaRegistry contract using the UID
    /// @param uid The UID of the schema to get.
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return schemaRegistry.getSchema(uid);
    }

    /// @notice Returns if the attestation is payable or not
    /// @return True if the attestation is payable, false otherwise
    function isPayable() public pure override returns (bool) {
        return false;
    }

    /// @notice Returns if the attestation is expired or not
    /// @param _recipientId The recipient ID to check
    function isAttestationExpired(address _recipientId) public view returns (bool) {
        if (easInfo.eas.getAttestation(attestations[_recipientId]).expirationTime < block.timestamp) {
            return true;
        }
        return false;
    }

    function onAttest(Attestation calldata, uint256) internal pure override returns (bool) {
        return true;
    }

    function onRevoke(Attestation calldata, uint256) internal pure override returns (bool) {
        return true;
    }
}
