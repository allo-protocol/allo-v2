// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// External Libraries
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";

// Test libraries
import {MockGatingExtension} from "../../utils/MockGatingExtension.sol";
import {BaseGatingExtension} from "./BaseGatingExtension.sol";
import {EASGatingExtension} from "../../../contracts/extensions/EASGatingExtension.sol";

contract EASGatingExtensionTest is BaseGatingExtension {
    function test_initialize() public {
        assertEq(gatingExtension.eas(), eas);
    }

    function testRevert_initialize_invalidEAS() public {
        MockGatingExtension _gatingExtension = new MockGatingExtension(allo);

        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_EAS_ADDRESS.selector);
        /// initialize
        vm.prank(allo);
        _gatingExtension.initialize(poolId, abi.encode(address(0)));
    }

    function test_onlyWithAttestation() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: _schema,
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: actor,
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }

    function testRevert_onlyWithAttestation_invalidSchema() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: keccak256("wrong"),
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: actor,
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_ATTESTATION_SCHEMA.selector);
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }

    function testRevert_onlyWithAttestation_invalidAttester() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: _schema,
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: address(0),
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_ATTESTATION_ATTESTER.selector);
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }
}
