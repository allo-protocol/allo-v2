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

    error ALREADY_ADDED();

    // The instance of the EAS and SchemaRegistry contracts.
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;

    bytes32 constant EMPTY_UID = 0;

    // Who can call submitAttestation
    mapping(address => bool) public attestationSigners;

    EnumerableSet.AddressSet private hackers;

    event EASAddressUpdated(address indexed easAddress);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    constructor(address _allo, string memory _name) QVSimpleStrategy(_allo, _name) {}

    /// @dev Initializes the strategy
    /// @param _poolId The pool ID for this strategy
    /// @param _data The data to initialize the strategy with
    function initialize(uint256 _poolId, bytes memory _data) public override {
        // decode the _data -> the second data has the timestamps and QVSimpleStrategy data
        (
            address easContractAddress,
            address schemaRegistryAddress,
            string memory schema,
            bool revocable,
            bytes memory data
        ) = abi.decode(_data, (address, address, string, bool, bytes));

        __HackathonQVStrategy_init(easContractAddress, schemaRegistryAddress, schema, revocable, _poolId, data);
    }

    /// @dev Initializes the strategy.
    function __HackathonQVStrategy_init(
        address _easContractAddress,
        address _schemaRegistryAddress,
        string memory _schema,
        bool _revocable,
        uint256 _poolId,
        bytes memory _data
    ) public {
        (
            registryGating,
            metadataRequired,
            maxVoiceCreditsPerAllocator,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, uint256));
        __QVSimpleStrategy_init(
            _poolId,
            registryGating,
            metadataRequired,
            maxVoiceCreditsPerAllocator,
            registrationStartTime,
            registrationEndTime,
            allocationStartTime,
            allocationEndTime
        );

        eas = IEAS(_easContractAddress);
        schemaRegistry = ISchemaRegistry(_schemaRegistryAddress);

        // Register the schema with the SchemaRegistry contract.
        // todo: setup a default schema they can use for now.
        // https://optimism-goerli.easscan.org/schema/create
        // https://docs.attest.sh/docs/tutorials/create-a-schema
        // https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/

        // todo: we will want to make a default one and then let the user override it if they want.
        // _registerSchema(_schema, ISchemaResolver(address(this)), _revocable);
    }

    /// =========================
    /// == Internal Functions ===
    /// =========================

    /// @dev Registers a recipient with the EAS contract.
    /// @param _data The data to register the recipient with.
    /// @param _sender The address of the sender.
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyPoolManager(_sender)
        returns (address recipientId)
    {
        // decode _data
        // Note: this _data will also contain another data bytes array to pass to _registerRecipient()
        (address recipient, uint256 amount, address token, bytes memory data) =
            abi.decode(_data, (address, uint256, address, bytes));

        // check if already added
        if (hackers.contains(_sender)) {
            revert ALREADY_ADDED();
        }
        // attest the recipient
        // todo: update the following values to be passed in
        uint64 expirationTime = uint64(block.timestamp + 100 days);
        bool revocable = true;

        // create the request
        AttestationRequest memory attestationRequest = AttestationRequest(
            // todo: add schema
            "",
            AttestationRequestData({
                recipient: recipient,
                expirationTime: expirationTime,
                revocable: revocable,
                refUID: EMPTY_UID,
                data: data,
                value: amount
            })
        );

        eas.attest(attestationRequest);

        // register the recipient
        return _registerRecipient(data, _sender);
    }

    /// @dev Allocates tokens to a recipient.
    /// @param _recipientId The ID of the recipient to allocate tokens to.
    /// @param _amount The amount of tokens to allocate.
    /// @param _token The address of the token to allocate.
    /// @param _data The data to allocate the tokens with.
    /// @param _sender The address of the sender.
    function _allocate(address _recipientId, uint256 _amount, address _token, bytes memory _data, address _sender)
        internal
    {}

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

    /// @dev Getter for the hackers set.
    function getHackers() public view returns (address[] memory) {
        address[] memory hackersArray = new address[](hackers.length());
        for (uint256 i = 0; i < hackers.length(); i++) {
            hackersArray[i] = hackers.at(i);
        }
        return hackersArray;
    }

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
    function getAttestation(bytes32 uid) public payable virtual returns (Attestation memory) {
        Attestation memory attestation = eas.getAttestation(uid);
        return attestation;
    }

    /// @dev Gets a schema from the SchemaRegistry contract.
    /// @param uid The UID of the schema to get.
    function getSchema(bytes32 uid) public payable virtual returns (SchemaRecord memory) {
        SchemaRecord memory schemaRecord = schemaRegistry.getSchema(uid);
        return schemaRecord;
    }

    function _getAllo() internal view returns (IAllo) {
        return IAllo(allo);
    }

    /// @dev Adds a verifier to the list of authorized verifiers.
    /// @param _verifier The address of the verifier to add.
    function addVerifier(address _verifier) public onlyPoolManager(msg.sender) {
        if (attestationSigners[_verifier]) {
            revert ALREADY_ADDED();
        }

        attestationSigners[_verifier] = true;

        emit VerifierAdded(_verifier);
    }

    /// @dev Removes a verifier from the list of authorized verifiers.
    /// @param _verifier The address of the verifier to remove.
    function removeVerifier(address _verifier) public onlyPoolManager(msg.sender) {
        if (!attestationSigners[_verifier]) {
            revert INVALID();
        }

        attestationSigners[_verifier] = false;

        emit VerifierRemoved(_verifier);
    }

    /// @dev Sets the address of the EAS contract.
    /// @param _easContractAddress The address of the EAS contract.
    function setEASAddress(address _easContractAddress) public onlyPoolManager(msg.sender) {
        eas = IEAS(_easContractAddress);

        emit EASAddressUpdated(_easContractAddress);
    }

    /// @dev Submit an attestation request to the EAS contract.
    /// @param _attestationRequestData An array of `AttestationRequestData` structures containing the attestation request data.
    function submitAttestation(MultiAttestationRequest[] calldata _attestationRequestData)
        public
        payable
        virtual
        onlyPoolManager(msg.sender)
        returns (bytes32[] memory)
    {
        if (!attestationSigners[msg.sender]) {
            revert INVALID();
        }

        return eas.multiAttest(_attestationRequestData);
    }

    /// @dev Revoke attestations by schema and uid
    /// @param _attestationRequestData An array of `MultiRevocationRequest` structures containing the attestations to revoke.
    function revokeAttestations(MultiRevocationRequest[] calldata _attestationRequestData) public payable virtual {
        if (!attestationSigners[msg.sender]) {
            revert INVALID();
        }

        eas.multiRevoke(_attestationRequestData);
    }
}
