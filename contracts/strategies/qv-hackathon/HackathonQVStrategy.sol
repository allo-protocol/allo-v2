// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {QVSimpleStrategy} from "../qv-simple/QVSimpleStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

import {EnumerableSet} from "@openzeppelin/utils/structs/EnumerableSet.sol";

// Note: EAS Contracts
import {
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    Attestation,
    MultiAttestationRequest,
    MultiRevocationRequest
} from "@ethereum-attestation-service/IEAS.sol";
import {ISchemaRegistry, ISchemaResolver, SchemaRecord} from "@ethereum-attestation-service/ISchemaRegistry.sol";

contract HackathonQVStrategy is QVSimpleStrategy {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct EASInfo {
        IEAS eas;
        ISchemaRegistry schemaRegistry;
        string schema;
        bool revocable;
    }

    /// ======================
    /// ==== Custom Error =====
    /// ======================

    error ALREADY_ADDED();

    /// ======================
    /// ====== Storage =======
    /// ======================

    EASInfo public easInfo;
    bytes32 constant _RELATED_ATTESTATION_UID = 0;
    address[] public allowedRecipients;

    /// ======================
    /// ====== Events ========
    /// ======================

    event EASAddressUpdated(address indexed easAddress);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

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
            true, // registryGating
            metadataRequired,
            maxVoiceCreditsPerAllocator,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime
        );

        easInfo = EASInfo({
            eas: _easInfo.eas,
            schemaRegistry: _easInfo.schemaRegistry,
            schema: _easInfo.schema,
            revocable: _easInfo.revocable
        });

        nft = ERC721(_nft);

        // Register the schema with the SchemaRegistry contract.
        // https://optimism-goerli.easscan.org/schema/create
        // https://docs.attest.sh/docs/tutorials/create-a-schema
        // https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/
        _registerSchema(_easInfo.schema, ISchemaResolver(address(this)), _easInfo.revocable);
    }

    /// ======================
    /// ====== External ======
    /// ======================

    /// Set the allowed recipient IDs
    /// @param _recipientIds The recipient IDs to allow
    function setAllowedRecipientIds(address[] _recipientIds)
        external
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            allowedRecipients[i] = _recipientIds[i];

            _grantEASAttestation(_recipientId);

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
        bool useRegistryAnchor;
        Metadata memory metadata;

        (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

        if (
            // TODO: HOW TO CHECK IF RECIPIENT ID has attestation from EAS contract?
            !_isIdentityMember(recipientId, _sender)
        ) {
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
        recipient.useRegistryAnchor = registryGating ? true : useRegistryAnchor;

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
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // check the voiceCreditsToAllocate is > 0
        if (voiceCreditsToAllocate <= 0) {
            revert INVALID();
        }

        // check the time periods for allocation
        if (block.timestamp < allocationStartTime || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }

        // check that the sender can allocate votes
        if (!nft.balanceOf(_sender) == 0) {
            revert UNAUTHORIZED();
        }

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (voiceCreditsToAllocate + allocator.voiceCredits > maxVoiceCreditsPerAllocator) {
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

        emit Allocated(_sender, voteResult, address(0), msg.sender);
    }

    /// @dev Grant EAS attestation to recipient with the EAS contract.
    // TODO: VERIFY THIS LOGIC
    function _grantEASAttestation(address _recipientId) internal {
        AttestationRequest memory attestationRequest = AttestationRequest(
            easInfo.schema,
            AttestationRequestData({
                recipient: _recipientId,
                expirationTime: expirationTime,
                revocable: easInfo.revocable,
                refUID: _RELATED_ATTESTATION_UID,
                data: data,
                value: amount
            })
        );

        eas.attest(attestationRequest);
    }

    /// =========================
    /// ==== DO WE NEED THIS ========
    /// =========================

    // /// @dev Registers a schema with the SchemaRegistry contract.
    // /// @param _schema The schema to register.
    // /// @param _resolver The address of the resolver contract.
    // /// @param _revocable Whether the schema is revocable.
    // function _registerSchema(string memory _schema, ISchemaResolver _resolver, bool _revocable)
    //     internal
    //     returns (bytes32)
    // {
    //     bytes32 uid = schemaRegistry.register(_schema, _resolver, _revocable);

    //     return uid;
    // }

    /// =========================
    /// ==== EAS Functions =====
    /// =========================

    // Note: basic setup for using EAS
    // Version: 0.27
    // * OP Goerli
    //    EAS Contract: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
    //    Schema Registry: 0x0a7E2Ff54e76B8E6659aedc9103FB21c038050D0
    // * Sepolia
    //    EAS Contract: 0x1a5650d0ecbca349dd84bafa85790e3e6955eb84
    //    Schema Registry: 0x7b24C7f8AF365B4E308b6acb0A7dfc85d034Cb3f

    /// @dev Gets an attestation from the EAS contract.
    /// @param uid The UUID of the attestation to get.
    // function getAttestation(bytes32 uid) public payable virtual returns (Attestation memory) {
    //     Attestation memory attestation = eas.getAttestation(uid);
    //     return attestation;
    // }

    // /// @dev Gets a schema from the SchemaRegistry contract.
    // /// @param uid The UID of the schema to get.
    // function getSchema(bytes32 uid) public payable virtual returns (SchemaRecord memory) {
    //     SchemaRecord memory schemaRecord = schemaRegistry.getSchema(uid);
    //     return schemaRecord;
    // }

    // /// @dev Adds a verifier to the list of authorized verifiers.
    // /// @param _verifier The address of the verifier to add.
    // function addVerifier(address _verifier) public onlyPoolManager(msg.sender) {
    //     if (attestationSigners[_verifier]) {
    //         revert ALREADY_ADDED();
    //     }

    //     attestationSigners[_verifier] = true;

    //     emit VerifierAdded(_verifier);
    // }

    // /// @dev Removes a verifier from the list of authorized verifiers.
    // /// @param _verifier The address of the verifier to remove.
    // function removeVerifier(address _verifier) public onlyPoolManager(msg.sender) {
    //     if (!attestationSigners[_verifier]) {
    //         revert INVALID();
    //     }

    //     attestationSigners[_verifier] = false;

    //     emit VerifierRemoved(_verifier);
    // }

    // /// @dev Sets the address of the EAS contract.
    // /// @param _easContractAddress The address of the EAS contract.
    // function setEASAddress(address _easContractAddress) public onlyPoolManager(msg.sender) {
    //     eas = IEAS(_easContractAddress);

    //     emit EASAddressUpdated(_easContractAddress);
    // }

    // /// @dev Revoke attestations by schema and uid
    // /// @param _attestationRequestData An array of `MultiRevocationRequest` structures containing the attestations to revoke.
    // function revokeAttestations(MultiRevocationRequest[] calldata _attestationRequestData) public payable virtual {
    //     if (!attestationSigners[msg.sender]) {
    //         revert INVALID();
    //     }

    //     eas.multiRevoke(_attestationRequestData);
    // }
}
