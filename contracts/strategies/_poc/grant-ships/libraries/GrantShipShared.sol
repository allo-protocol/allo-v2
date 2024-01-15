// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "../../../../core/libraries/Metadata.sol";
import {IStrategy} from "../../../../core/interfaces/IStrategy.sol";

/// ================================
/// ========== Structs =============
/// ================================

/// @notice Struct to hold the init params for the strategy
struct ShipInitData {
    bool registryGating;
    bool metadataRequired;
    bool grantAmountRequired;
    string shipName;
    Metadata shipMetadata;
    address recipientId;
    uint256 operatorHatId;
    uint256 facilitatorHatId;
}
