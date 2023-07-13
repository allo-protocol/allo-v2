// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

<<<<<<< HEAD
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
=======
interface IStrategy {
>>>>>>> modules
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
<<<<<<< HEAD
    }

    struct ResultSummary {
        address recipientId;
        uint256 votes;
=======
>>>>>>> modules
    }

    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external;
    // the default BaseStrategy version will not use the data
    // if a strtegy wants to use it, they will overwrite it, use it, and then call super.initialize()

<<<<<<< HEAD
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
=======
    function skim(address token) external;
    // this is used to check Allo.sol for the amount of funding there should be
    // then checking the balance of the contract, and paying the difference

    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);
    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept

    function getRecipientStatus(address _recipientId) public view returns (RecipientStatus);
    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected

    function isValidAllocater(address _voter) public view returns (bool);
    // simply returns whether a voter is valid or not, will usually be true for all

    function allocate(bytes memory _data, address _sender) external payable;
    // only called via allo.sol by users to allocate votes to a recipient
    // this will update some data in this contract to store votes, etc.

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
>>>>>>> modules
}
