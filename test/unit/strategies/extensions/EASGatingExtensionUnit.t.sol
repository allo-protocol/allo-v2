// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockEASGatingExtension} from "test/smock/MockMockEASGatingExtension.sol";
import {EASGatingExtension} from "contracts/strategies/extensions/gating/EASGatingExtension.sol";
import {Attestation} from "eas-contracts/IEAS.sol";

contract EASGatingExtensionUnit is Test {
    MockMockEASGatingExtension easGatingExtension;

    function setUp() public {
        easGatingExtension = new MockMockEASGatingExtension(address(0));
    }

    function test___EASGatingExtension_initShouldRevertIf_easIsZeroAddress() external {
        // It should revert if _eas is zero address
        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_EAS_ADDRESS.selector);

        easGatingExtension.call___EASGatingExtension_init(address(0));
    }

    function test___EASGatingExtension_initWhen_easIsNotZeroAddress(address _eas) external {
        vm.assume(_eas != address(0));

        easGatingExtension.call___EASGatingExtension_init(_eas);

        // It should set the EAS address
        assertEq(easGatingExtension.eas(), _eas);
    }

    function test__checkOnlyWithAttestationShouldCallGetAttestationInEasContract(
        bytes32 _schema,
        address _attester,
        bytes32 _uid
    ) external {
        vm.mockCall(
            address(easGatingExtension.eas()),
            abi.encodeWithSignature("getAttestation(bytes32)", _uid),
            abi.encode(
                Attestation(
                    _uid,
                    _schema,
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    bytes32(0), // not relevant
                    address(0), // not relevant
                    _attester,
                    false, // not relevant
                    bytes("") // not relevant
                )
            )
        );

        // It should call getAttestation in eas contract
        vm.expectCall(address(easGatingExtension.eas()), abi.encodeWithSignature("getAttestation(bytes32)", _uid));

        easGatingExtension.call__checkOnlyWithAttestation(_schema, _attester, _uid);
    }

    function test__checkOnlyWithAttestationRevertWhen_SchemaIsDifferentThanReturned(
        bytes32 _schema,
        bytes32 _returnedSchema,
        address _attester,
        bytes32 _uid
    ) external {
        vm.mockCall(
            address(easGatingExtension.eas()),
            abi.encodeWithSignature("getAttestation(bytes32)", _uid),
            abi.encode(
                Attestation(
                    _uid,
                    _returnedSchema,
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    bytes32(0), // not relevant
                    address(0), // not relevant
                    _attester,
                    false, // not relevant
                    bytes("") // not relevant
                )
            )
        );

        // It should revert
        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_ATTESTATION_SCHEMA.selector);

        easGatingExtension.call__checkOnlyWithAttestation(_schema, _attester, _uid);
    }

    function test__checkOnlyWithAttestationRevertWhen_AttesterIsDifferentThanReturned(
        bytes32 _schema,
        address _attester,
        address _returnedAttester,
        bytes32 _uid
    ) external {
        vm.mockCall(
            address(easGatingExtension.eas()),
            abi.encodeWithSignature("getAttestation(bytes32)", _uid),
            abi.encode(
                Attestation(
                    _uid,
                    _schema,
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    uint64(0), // not relevant
                    bytes32(0), // not relevant
                    address(0), // not relevant
                    _returnedAttester,
                    false, // not relevant
                    bytes("") // not relevant
                )
            )
        );

        // It should revert
        vm.expectRevert(EASGatingExtension.EASGatingExtension_INVALID_ATTESTATION_ATTESTER.selector);

        easGatingExtension.call__checkOnlyWithAttestation(_schema, _attester, _uid);
    }
}
