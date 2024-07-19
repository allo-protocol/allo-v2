// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGatingExtension {
    /// ================================
    /// ========== Errors ==============
    /// ================================
    /// @notice Throws when the token is zero address
    error GatingExtension_INVALID_TOKEN();
    /// @notice Throws when the actor is zero address
    error GatingExtension_INVALID_ACTOR();
    /// @notice Throws when the balance of the actor is insufficient
    error GatingExtension_INSUFFICIENT_BALANCE();
    /// @notice Throws when the attestation schema is wrong
    error GatingExtension_INVALID_ATTESTATION_SCHEMA();
    /// @notice Throws when the attester is wrong
    error GatingExtension_INVALID_ATTESTATION_ATTESTER();

    /// @notice Stores the details needed for initializing strategy
    /// @param eas The EAS contract address
    struct GatingExtensionInitializeParams {
        address eas;
    }
}
