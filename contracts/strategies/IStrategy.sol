// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../core/IAllo.sol";

/// @title IStrategy Interface
/// @author allo-team
///
/// @dev Interface for strategy imlementations, BaseStrategy inherits from this
///
/// NOTE: BaseStrategy is the base contract that all strategies should inherit from
interface IStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @dev The RecipientStatus enum that all recipients are based from
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    /// @dev Payout summary struct to hold the payout data
    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    /// @dev Returns when calls to Base Strategy are unauthorized
    error BaseStrategy_UNAUTHORIZED();

    /// @dev Returns when Base Strategy is already initialized
    error BaseStrategy_ALREADY_INITIALIZED();

    /// @dev Returns when Base Strategy is not initialized
    error BaseStrategy_NOT_INITIALIZED();

    /// @dev Returns when an invalid address is used
    error BaseStrategy_INVALID_ADDRESS();

    /// @dev Returns when a pool is inactive
    error BaseStrategy_POOL_INACTIVE();

    /// @dev Returns when a pool is already active
    error BaseStrategy_POOL_ACTIVE();

    /// @dev Returns when two arrays length are not equal
    error BaseStrategy_ARRAY_MISMATCH();

    /// @dev Returns as a general error when either a recipient address or an amount is invalid
    error BaseStrategy_INVALID();

    /// ======================
    /// ======= Events =======
    /// ======================

    /// Event emitted when strategy is initialized
    event Initialized(address allo, bytes32 profileId, uint256 poolId, bytes data);

    /// Event emitted when a recipient is registered
    event Registered(address indexed recipientId, bytes data, address sender);

    /// Event emitted when a recipient is allocated to
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);

    /// Event emitted when tokens are distributed
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);

    /// Event emitted when pool is set to active status
    event PoolActive(bool active);

    /// ======================
    /// ======= Views ========
    /// ======================

    /// @dev Getter for the address of the Allo contract
    function getAllo() external view returns (IAllo);

    /// @dev Getter for the 'poolId' for this strategy
    function getPoolId() external view returns (uint256);

    /// @dev Getter for the 'id' of the strategy
    function getStrategyId() external view returns (bytes32);

    /// @dev Returns whether a allocator is valid or not, will usually be true for all
    ///      and will depend on the strategy implementation
    function isValidAllocator(address _allocator) external view returns (bool);

    /// @dev whether pool is active
    function isPoolActive() external returns (bool);

    /// @dev returns the amount of tokens in the pool
    function getPoolAmount() external view returns (uint256);

    /// incrases the poolAmount which is set on invoking Allo.fundPool
    function increasePoolAmount(uint256 _amount) external;

    /// @dev Returns the status of a recipient probably tracked in a mapping, but will depend on the implementation
    ///      for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    ///      since there is no need for Pending or Rejected
    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus);

    /// @return Input the values you would send to distribute(), get the amounts each recipient in the array would receive
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        returns (PayoutSummary[] memory);

    /// ======================
    /// ===== Functions ======
    /// ======================

    /// @dev The default BaseStrategy version will not use the data
    ///      if a strtegy wants to use it, they will overwrite it, use it, and then call super.initialize()
    function initialize(uint256 _poolId, bytes memory _data) external;

    /// @dev This is called via Allo.sol to register recipients
    ///      it can change their status all the way to Accepted, or to Pending if there are more steps
    ///      if there are more steps, additional functions should be added to allow the owner to check
    ///      this could also check attestations directly and then Accept
    ///
    /// Requirements: This will be determined by the strategy
    ///
    function registerRecipient(bytes memory _data, address _sender) external payable returns (address);

    /// @dev Only called via Allo.sol by users to allocate to a recipient
    ///      this will update some data in this contract to store votes, etc
    ///
    /// Requirements: This will be determined by the strategy
    ///
    function allocate(bytes memory _data, address _sender) external payable;

    /// @dev This will distribute tokens to recipients
    ///
    /// NOTE: Most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference.
    ///       This contract will need to track the amount paid already, so that it doesn't double pay
    ///
    /// Requirements: This will be determined by the strategy
    ///
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
