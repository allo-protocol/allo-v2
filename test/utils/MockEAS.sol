// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    Attestation, AttestationRequest, AttestationRequestData, IEAS, RevocationRequest
} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry, ISchemaResolver, SchemaRecord} from "eas-contracts/ISchemaRegistry.sol";

contract MockEAS {
    Attestation public mockAttestation = Attestation({
        uid: bytes32("123"),
        schema: bytes32("123"),
        time: 1,
        expirationTime: 2,
        revocationTime: 3,
        refUID: bytes32("123"),
        recipient: address(123),
        attester: address(123),
        revocable: true,
        data: abi.encode("123")
    });

    function attest(AttestationRequest calldata request) external payable returns (bytes32) {
        request;
        return bytes32("123");
    }

    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        uid;
        return mockAttestation;
    }
}

contract MockSchemaRegistry {
    function register(string memory schema, address resolver, bool revocable) public pure returns (bytes32) {
        schema;
        resolver;
        revocable;
        return bytes32("123");
    }

    function getSchema(bytes32 uid) public pure returns (SchemaRecord memory) {
        uid;
        return SchemaRecord(bytes32("123"), ISchemaResolver(address(0)), true, "123");
    }
}
