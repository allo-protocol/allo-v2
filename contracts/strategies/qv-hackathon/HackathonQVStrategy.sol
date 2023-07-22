// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {QVSimpleStrategy} from "../qv-simple/QVSimpleStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

import {ERC721} from "@solady/tokens/ERC721.sol";

// Note: EAS Contracts
import {
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    Attestation,
    RevocationRequest,
    RevocationRequestData
} from "@ethereum-attestation-service/IEAS.sol";
import {ISchemaRegistry, ISchemaResolver, SchemaRecord} from "@ethereum-attestation-service/ISchemaRegistry.sol";
import {SchemaResolver} from "@ethereum-attestation-service/resolver/SchemaResolver.sol";

contract HackathonQVStrategy is QVSimpleStrategy, SchemaResolver {
    // Note: There are two ways to use/create a schema
    // 1. The user passes in a schema UID and the strategy uses that schema
    // 2. The user passes in a schema string and the strategy registers that schema with the SchemaRegistry contract
    struct EASInfo {
        IEAS eas;
        ISchemaRegistry schemaRegistry;
        bytes32 schemaUid; // the schema UID they madek previously
        string schema; //  the schema they wish to create
        bool revocable;
    }

    /// ======================
    /// ==== Custom Error =====
    /// ======================

    error ALREADY_ADDED();
    error OUT_OF_BOUNDS();

    /// ======================
    /// ====== Storage =======
    /// ======================

    // The instance of the EAS and SchemaRegistry contracts.
    ISchemaRegistry public schemaRegistry;
    ERC721 public nft;

    address[] private allowedRecipients;

    EASInfo public easInfo;
    bytes32 constant _RELATED_ATTESTATION_UID = 0;

    // will the attestation be payable?
    // uint256 private immutable _incentive;

    // Who can call submitAttestation
    mapping(address => bool) public attestationSigners;

    // Who has attested
    mapping(address => Attestation) public attestations;

    /// ======================
    /// ====== Events ========
    /// ======================

    event EAS_UPDATED(address easAddress);

    /// ======================
    /// ===== Constructor ====
    /// ======================

    constructor(address _allo, string memory _name, IEAS _eas) QVSimpleStrategy(_allo, _name) SchemaResolver(_eas) {}

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
            schemaUid: _easInfo.schemaUid,
            revocable: _easInfo.revocable
        });

        nft = ERC721(_nft);

        // Register the schema with the SchemaRegistry contract when required.
        // https://optimism-goerli.easscan.org/schema/create
        // https://docs.attest.sh/docs/tutorials/create-a-schema
        // https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/

        // Note: Check if the user needs to create a new schema or use an existing one
        if (_easInfo.schemaUid == _RELATED_ATTESTATION_UID && bytes(_easInfo.schema).length > 0) {
            _registerSchema(_easInfo.schema, ISchemaResolver(address(this)), _easInfo.revocable);
        }
    }

    // TODO: ====== REMOVE THIS / FOR REFERENCE ONLY ==========
    // struct Attestation {
    //     bytes32 uid; // A unique identifier of the attestation.
    //     bytes32 schema; // The unique identifier of the schema.
    //     uint64 time; // The time when the attestation was created (Unix timestamp).
    //     uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    //     uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    //     bytes32 refUID; // The UID of the related attestation.
    //     address recipient; // The recipient of the attestation.
    //     address attester; // The attester/sender of the attestation.
    //     bool revocable; // Whether the attestation is revocable.
    //     bytes data; // Custom attestation data.
    // }

    /// ======================
    /// ====== External ======
    /// ======================

    /// @notice Returns if the attestation is payable or not
    /// @return True if the attestation is payable, false otherwise
    function isPayable() public pure override returns (bool) {
        // Note: return the _incentive if we want more flexibility
        return false;
    }

    /// @notice Returns if the attestation is expired or not
    /// @param _recipientId The recipient ID to check
    /// @return True if the attestation is expired, false otherwise
    function isAttestationExpired(address _recipientId) public view returns (bool) {
        if (attestations[_recipientId].expirationTime < block.timestamp) {
            return true;
        }

        return false;
    }

    function revokeAttestation(address _recipientId) public {
        RevocationRequestData memory revocationRequestData =
            RevocationRequestData({uid: attestations[_recipientId].uid, value: 0});
        RevocationRequest memory revocationRequest =
            RevocationRequest({schema: attestations[_recipientId].schema, data: revocationRequestData});

        _revokeAttestation(revocationRequest);
    }

    /// @notice These are the resolver function for the attestions

    // TODO: Finish these functions with a simple example for the hackathon.

    // Note: if a payable attestation is required, we can use the uint256 _value to send the incentive
    /// @notice This is the resolver function for the attestion
    /// @param _attestation The attestation to resolve
    function onAttest(Attestation calldata _attestation, uint256) internal override returns (bool) {
        // Note: we can pretty much do whatever we want here...
        // example here is adding the attestation to the attestations mapping for later use.
        attestations[_attestation.attester] = _attestation;

        // TODO: mint the NFT?
        // Note: not sure how to pull this off yet, ERC721 does not expose a public mint funciton by default and
        // can be named just about anything by the token creator.
        // A default 1155 token may work better in this use-case/example, then we don't need an id to send the mint funciton.
        // nft.mint(_attestation.attester, 1);

        return easInfo.eas.isAttestationValid(_toBytes32(_attestation.data, 0));
    }

    /// @notice This is the resolver function for the revocation
    function onRevoke(Attestation calldata _attestation, uint256) internal override returns (bool) {
        // Note: we can pretty much do whatever we want here also...
        // example here is updating the attestation in the attestations mapping.
        attestations[_attestation.attester] = _attestation;

        return easInfo.eas.isAttestationValid(_toBytes32(_attestation.data, 0));
    }

    /// @notice END Resolver Funcitons

    /// Set the allowed recipient IDs
    /// @param _recipientIds The recipient IDs to allow
    function setAllowedRecipientIds(address[] memory _recipientIds)
        external
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        // REVOKE OLDER ATTEASTIONS.

        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            allowedRecipients[i] = _recipientIds[i];

            // todo: where is the rest of the data?
            _grantEASAttestation(_recipientIds[i], 0, "", 0);

            unchecked {
                i++;
            }
        }
    }

    function toBytes32(bytes memory data, uint256 start) external pure returns (bytes32) {
        return _toBytes32(data, start);
    }

    /// =========================
    /// == Internal Functions ===
    /// =========================

    /// @notice Check if the attestation is valid
    /// @param _recipientId The recipient ID to check
    /// @return True if the attestation is valid, false otherwise
    function _isAttestationValid(address _recipientId) internal view returns (bool) {
        Attestation memory attestation = attestations[_recipientId];

        return easInfo.eas.isAttestationValid(_toBytes32(attestation.data, 0));
    }

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

        if (_isAttestationValid(recipientId) && !_isIdentityMember(recipientId, _sender)) {
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
        if (nft.balanceOf(_sender) == 0) {
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
    /// @param _recipientId The recipient ID to grant the attestation to.
    /// @param _expirationTime The expiration time of the attestation.
    /// @param _data The data to include in the attestation.
    /// @param _value The value to send with the attestation.
    function _grantEASAttestation(address _recipientId, uint64 _expirationTime, bytes memory _data, uint256 _value)
        internal
    {
        AttestationRequest memory attestationRequest = AttestationRequest(
            easInfo.schemaUid,
            AttestationRequestData({
                recipient: _recipientId,
                expirationTime: _expirationTime,
                revocable: easInfo.revocable,
                refUID: _RELATED_ATTESTATION_UID,
                data: _data,
                value: _value
            })
        );

        easInfo.eas.attest(attestationRequest);
    }

    // Note: We need this to register the schema the pool manager wants to use for the attestations when they don't have a UID
    /// @dev Registers a schema with the SchemaRegistry contract.
    /// @param _schema The schema to register.
    /// @param _resolver The address of the resolver contract.
    /// @param _revocable Whether the schema is revocable.
    function _registerSchema(string memory _schema, ISchemaResolver _resolver, bool _revocable)
        internal
        returns (bytes32)
    {
        bytes32 uid = schemaRegistry.register(_schema, _resolver, _revocable);

        return uid;
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
    function getAttestation(bytes32 uid) public payable virtual returns (Attestation memory) {
        Attestation memory attestation = easInfo.eas.getAttestation(uid);
        return attestation;
    }

    /// @dev Gets a schema from the SchemaRegistry contract using the UID
    /// @param uid The UID of the schema to get.
    function getSchema(bytes32 uid) public payable virtual returns (SchemaRecord memory) {
        SchemaRecord memory schemaRecord = schemaRegistry.getSchema(uid);
        return schemaRecord;
    }

    /// Note: Allows user to set the EAS contract address if they want to use a different one than the default.
    /// @dev Sets the address of the EAS contract.
    /// @param _easContractAddress The address of the EAS contract.
    function setEASAddress(address _easContractAddress) public onlyPoolManager(msg.sender) {
        easInfo.eas = IEAS(_easContractAddress);

        emit EAS_UPDATED(_easContractAddress);
    }

    // @dev Revoke attestations
    /// @param _revocatonRequest An `RevocationRequest` structure containing the attestation to revoke.
    function _revokeAttestation(RevocationRequest memory _revocatonRequest) internal virtual {
        if (!attestationSigners[msg.sender]) {
            revert INVALID();
        }

        easInfo.eas.revoke(_revocatonRequest);
    }

    function _toBytes32(bytes memory data, uint256 start) private pure returns (bytes32) {
        unchecked {
            if (data.length < start + 32) {
                revert OUT_OF_BOUNDS();
            }
        }

        bytes32 tempBytes32;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(data, 0x20), start))
        }

        return tempBytes32;
    }
}
