// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../core/IAllo.sol";

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

    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    // BaseStrategy errors
    error BaseStrategy_UNAUTHORIZED();
    error BaseStrategy_ALREADY_INITIALIZED();
    error BaseStrategy_NOT_INITIALIZED();
    error BaseStrategy_INVALID_ADDRESS();
    error BaseStrategy_POOL_INACTIVE();

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);
    event Registered(address indexed recipientId, bytes data, address sender);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);
    event PoolActive(bool active);

    /// ======================
    /// ======= Views ========
    /// ======================

    /// @return Address of the Allo contract
    function getAllo() external view returns (IAllo);

    /// @return Pool ID for this strategy
    function getPoolId() external view returns (uint256);

    /// @return The id of the strategy
    function getStrategyId() external view returns (bytes32);

    /// @return whether a allocator is valid or not, will usually be true for all
    function isValidAllocator(address _allocator) external view returns (bool);

    /// @return whether pool is active
    function isPoolActive() external returns (bool);

    /// @return returns the amount of tokens in the pool
    function getPoolAmount() external view returns (uint256);

    /// incrases the poolAmount which is set on invoking Allo.fundPool
    function increasePoolAmount(uint256 _amount) external;

    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected
    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus);

    /// @return Input the values you would send to distribute(), get the amounts each recipient in the array would receive
    function getPayouts(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        view
        returns (PayoutSummary[] memory);

    /// ======================
    /// ===== Functions ======
    /// ======================

    // the default BaseStrategy version will not use the data
    // if a strtegy wants to use it, they will overwrite it, use it, and then call super.initialize()
    function initialize(uint256 _poolId, bytes memory _data) external;

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function registerRecipient(bytes memory _data, address _sender) external payable returns (address);

    // only called via allo.sol by users to allocate to a recipient
    // this will update some data in this contract to store votes, etc.
    function allocate(bytes memory _data, address _sender) external payable;

    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
