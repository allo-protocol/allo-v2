// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IRecipientEligibilityModule} from "./modules/recipient/IRecipientEligibilityModule.sol";
import {IVotingModule} from "./modules/voting/IVotingModule.sol";
import {IVoterEligibilityModule} from "./modules/voter/IVoterEligibilityModule.sol";
import {IAllocationModule} from "./modules/allocation/IAllocationModule.sol";
import {IDistributionModule} from "./modules/distribution/IDistributionModule.sol";

abstract contract IStrategy is
    IRecipientEligibilityModule,
    IVoterEligibilityModule,
    IVotingModule,
    IAllocationModule,
    IDistributionModule
{
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    struct ResultSummary {
        address recipientId;
        uint256 votes;
    }

    struct PayoutSummary {
        address recipientId;
        uint256 amount;
    }

    function initialize(
        bytes32 _identityId,
        uint256 _poolId,
        bytes memory _recipientEligibilityData,
        bytes memory _voterEligibilityData,
        bytes memory _votingData,
        bytes memory _allocationData,
        bytes memory _distributionData
    ) external;

    function skim(address token) external;
}
