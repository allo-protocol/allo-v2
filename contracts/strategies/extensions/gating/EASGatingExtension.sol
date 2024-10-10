// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Imports
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";

// Internal Imports
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";

/// @title EAS Gating Extension
/// @notice This contract is providing gating options for a strategy's calls
/// @dev This contract is inheriting BaseStrategy
abstract contract EASGatingExtension is BaseStrategy {
    /// ================================
    /// ========== Errors ==============
    /// ================================

    /// @notice Throws when EAS address is zero
    error EASGatingExtension_InvalidEASAddress();
    /// @notice Throws when the attestation schema is wrong
    error EASGatingExtension_InvalidAttestationSchema();
    /// @notice Throws when the attester is wrong
    error EASGatingExtension_InvalidAttestationAttester();

    /// ================================
    /// ========== Storage =============
    /// ================================
    /// @notice The EAS contract
    address public eas;

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================
    /// @notice This initializes the strategy
    /// @param _eas The eas address
    function __EASGatingExtension_init(address _eas) internal virtual {
        if (_eas == address(0)) revert EASGatingExtension_InvalidEASAddress();
        /// Set the EAS contract
        eas = _eas;
    }

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// @notice This modifier checks if the sender attest to a schema
    /// @param _schema The unique identifier of the schema
    /// @param _attester The attester address
    /// @param _uid The unique identifier of the attestation
    modifier onlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid) {
        _checkOnlyWithAttestation(_schema, _attester, _uid);
        _;
    }

    /// ===============================
    /// ======= Internal Functions ====
    /// ===============================

    /// @notice This function checks if the sender has attested to a schema
    /// @param _schema The unique identifier of the schema
    /// @param _attester The attester address
    /// @param _uid The unique identifier of the attestation
    function _checkOnlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid) internal view virtual {
        Attestation memory _attestation = IEAS(eas).getAttestation(_uid);
        if (_attestation.schema != _schema) revert EASGatingExtension_InvalidAttestationSchema();
        if (_attestation.attester != _attester) revert EASGatingExtension_InvalidAttestationAttester();
    }
}
