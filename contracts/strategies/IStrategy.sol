// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Allo} from "../core/Allo.sol";

interface IStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    error BaseStrategy_UNAUTHORIZED();
    error BaseStrategy_STRATEGY_ALREADY_INITIALIZED();
    error BaseStrategy_INVALID_ADDRESS();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);
    event Skim(address skimmer, address token, uint256 amountToTreasury, uint256 amountToSkimmer);

    /// ======================
    /// ======= Views ========
    /// ======================

    /// @return Address of the Allo contract
    function getAllo() external view returns (Allo);

    /// @return Pool ID for this strategy
    function getPoolId() external view returns (uint256);

    /// @return The id of the strategy
    function getStrategyId() external view returns (bytes32);

    // simply returns whether a allocator is valid or not, will usually be true for all
    function isValidAllocator(address _allocator) external view returns (bool);

    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected
    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus);

    /// ======================
    /// ===== Functions ======
    /// ======================

    // the default BaseStrategy version will not use the data
    // if a strtegy wants to use it, they will overwrite it, use it, and then call super.initialize()
    function initialize(uint256 _poolId, bytes memory _data) external;

    // this is used to check Allo.sol for the amount of funding there should be
    // then checking the balance of the contract, and paying the difference
    function skim(address token) external;

    /// @return Input the values you would send to distribute(), get the amounts each recipient in the array would receive
    function getPayouts(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        returns (uint256[] memory);

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);

    // only called via allo.sol by users to allocate to a recipient
    // this will update some data in this contract to store votes, etc.
    function allocate(bytes memory _data, address _sender) external payable;

    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
