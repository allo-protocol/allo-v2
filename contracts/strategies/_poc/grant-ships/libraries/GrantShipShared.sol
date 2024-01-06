// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "../../../../core/libraries/Metadata.sol";
import {IStrategy} from "../../../../core/interfaces/IStrategy.sol";

/// ================================
/// ========== Structs =============
/// ================================

/// @notice Struct to hold details about the milestone
struct Milestone {
    uint256 amountPercentage;
    Metadata metadata;
    IStrategy.Status milestoneStatus;
}

/// @notice Struct to hold the init params for the strategy
struct ShipInitData {
    bool registryGating;
    bool metadataRequired;
    bool grantAmountRequired;
    string shipName;
    Metadata shipMetadata;
    address teamAddress;
    uint256 operatorHatId;
}
