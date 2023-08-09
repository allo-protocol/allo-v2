// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    EIP712Signature,
    IEAS,
    RevocationRequest
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {
    ISchemaRegistry,
    ISchemaResolver,
    SchemaRecord
} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";

contract MockEAS {
    uint256 dummyNonce;
    /**
     * @dev A struct representing the full arguments of the full delegated attestation request.
     */

    // struct DelegatedAttestationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     AttestationRequestData data; // The arguments of the attestation request.
    //     EIP712Signature signature; // The EIP712 signature data.
    //     address attester; // The attesting account.
    // }

    // /**
    //  * @dev A struct representing the full arguments of the multi attestation request.
    //  */
    // struct MultiAttestationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     AttestationRequestData[] data; // The arguments of the attestation request.
    // }

    // /**
    //  * @dev A struct representing the full arguments of the delegated multi attestation request.
    //  */
    // struct MultiDelegatedAttestationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     AttestationRequestData[] data; // The arguments of the attestation requests.
    //     EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    //     address attester; // The attesting account.
    // }

    // /**
    //  * @dev A struct representing the arguments of the revocation request.
    //  */
    // struct RevocationRequestData {
    //     bytes32 uid; // The UID of the attestation to revoke.
    //     uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
    // }

    // /**
    //  * @dev A struct representing the arguments of the full delegated revocation request.
    //  */
    // struct DelegatedRevocationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     RevocationRequestData data; // The arguments of the revocation request.
    //     EIP712Signature signature; // The EIP712 signature data.
    //     address revoker; // The revoking account.
    // }

    // /**
    //  * @dev A struct representing the full arguments of the multi revocation request.
    //  */
    // struct MultiRevocationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     RevocationRequestData[] data; // The arguments of the revocation request.
    // }

    // /**
    //  * @dev A struct representing the full arguments of the delegated multi revocation request.
    //  */
    // struct MultiDelegatedRevocationRequest {
    //     bytes32 schema; // The unique identifier of the schema.
    //     RevocationRequestData[] data; // The arguments of the revocation requests.
    //     EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    //     address revoker; // The revoking account.
    // }

    // function getSchemaRegistry() external pure returns (ISchemaRegistry) {
    //     return ISchemaRegistry(address(0));
    // }

    function attest(AttestationRequest calldata request) external payable returns (bytes32) {
        request;
        dummyNonce++;
        return bytes32(0);
    }

    // function attestByDelegation(DelegatedAttestationRequest calldata delegatedRequest)
    //     external
    //     payable
    //     returns (bytes32)
    // {
    //     delegatedRequest;
    //     dummyNonce++;
    //     return bytes32(0);
    // }

    // function multiAttest(MultiAttestationRequest[] calldata multiRequests)
    //     external
    //     payable
    //     returns (bytes32[] memory)
    // {
    //     multiRequests;
    //     dummyNonce++;
    //     return new bytes32[](0);
    // }

    // function multiAttestByDelegation(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
    //     external
    //     payable
    //     returns (bytes32[] memory)
    // {
    //     multiDelegatedRequests;
    //     dummyNonce++;
    //     return new bytes32[](0);
    // }

    // function revoke(RevocationRequest calldata request) external payable {
    //     request;
    //     dummyNonce++;
    // }

    // function revokeByDelegation(DelegatedRevocationRequest calldata delegatedRequest) external payable {
    //     delegatedRequest;
    //     dummyNonce++;
    // }

    // function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable {
    //     multiRequests;
    //     dummyNonce++;
    // }

    // function multiRevokeByDelegation(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
    //     external
    //     payable
    // {
    //     multiDelegatedRequests;
    //     dummyNonce++;
    // }

    // function timestamp(bytes32 data) external returns (uint64) {
    //             data;

    //     dummyNonce++;
    //     return uint64(0);
    // }

    // function multiTimestamp(bytes32[] calldata data) external returns (uint64) {
    //             data;

    //     dummyNonce++;
    //     return uint64(0);
    // }

    // function revokeOffchain(bytes32 data) external returns (uint64) {
    //             data;

    //     dummyNonce++;
    //     return uint64(0);
    // }

    // function multiRevokeOffchain(bytes32[] calldata data) external returns (uint64) {
    //     data;
    //     dummyNonce++;
    //     return uint64(0);
    // }

    function getAttestation(bytes32 uid) external pure returns (Attestation memory) {
        bytes32 schema; // The unique identifier of the schema.
        uint64 time; // The time when the attestation was created (Unix timestamp).
        uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
        uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
        bytes32 refUID; // The UID of the related attestation.
        address recipient; // The recipient of the attestation.
        address attester; // The attester/sender of the attestation.
        bool revocable; // Whether the attestation is revocable.
        bytes memory data; // Custom attestation data.
        return Attestation({
            uid: uid,
            schema: schema,
            time: time,
            expirationTime: expirationTime,
            revocationTime: revocationTime,
            refUID: refUID,
            recipient: recipient,
            attester: attester,
            revocable: revocable,
            data: data
        });
    }

    // function isAttestationValid(bytes32 uid) external pure returns (bool) {
    //     uid;
    //     return true;
    // }

    // function getTimestamp(bytes32 data) external pure returns (uint64) {
    //     data;
    //     return uint64(0);
    // }

    // function getRevokeOffchain(address revoker, bytes32 data) external pure returns (uint64) {
    //     revoker;
    //     data;
    //     return uint64(0);
    // }
}

contract MockSchemaRegistry {
    function register(string memory schema, address resolver, bool revocable) public pure returns (bytes32) {
        schema;
        resolver;
        revocable;
        return bytes32("123");
    }

    function getSchema(bytes32 uid) public pure returns (string memory) {
        uid;
        return "123";
    }
}