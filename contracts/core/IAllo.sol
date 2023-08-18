// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IRegistry} from "./IRegistry.sol";
import {IStrategy} from "../strategies/IStrategy.sol";
// Internal Libraries
import {Metadata} from "./libraries/Metadata.sol";

// @title Allo Interface
// @author allo-team
// @notice Interface for the Allo contract and exposes all functions needed to use the Allo protocol
// @dev This is the main contract that will be used to interact with the Allo protocol
interface IAllo {
    /// ======================
    /// ======= Structs ======
    /// ======================

    // @dev the Pool struct that all strategy pools are based from
    struct Pool {
        bytes32 profileId;
        IStrategy strategy;
        address token;
        Metadata metadata;
        bytes32 managerRole;
        bytes32 adminRole;
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    // @dev Returned when access is not authorized
    error UNAUTHORIZED();

    // @dev Returned when the 'msg.sender' has not sent enough funds
    error NOT_ENOUGH_FUNDS();

    // @dev Returned when the strategy is not approved
    error NOT_APPROVED_STRATEGY();

    // @dev Returned when the strategy is approved and should be cloned
    error IS_APPROVED_STRATEGY();

    // @dev Returned when Encoded '_data' length does not match _poolIds length
    error MISMATCH();

    // @dev Returned when any address is the zero address
    error ZERO_ADDRESS();

    // @dev Returned when the fee is below 1e18 which is the fee percentage denominator
    error INVALID_FEE();

    /// ======================
    /// ======= Events =======
    /// ======================

    // @dev Event emitted when a new pool is created
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    // @dev Event emitted when a pools metadata is updated
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    // @dev Event emitted when a pool is funded
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    // @dev Event emitted when the base fee is paid
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    // @dev Event emitted when the treasury address is updated
    event TreasuryUpdated(address treasury);

    // @dev Event emitted when the percent fee is updated
    event PercentFeeUpdated(uint256 percentFee);

    // @dev Event emitted when the base fee is updated
    event BaseFeeUpdated(uint256 baseFee);

    // @dev Event emitted when the registry address is updated
    event RegistryUpdated(address registry);

    // @dev Event emitted when a strategy is approved and added to the cloneable strategies mapping
    event StrategyApproved(address strategy);

    // @dev Event emitted when a strategy is removed from the cloneable strategies mapping
    event StrategyRemoved(address strategy);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    // @dev Initialize the Allo contract
    //
    // Requirements:
    //
    function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee) external;

    // @dev Updates the pools metadata
    //
    // Requirements: 'msg.sender' must be a pool admin
    //
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external;

    // @dev Updates the registry address and emits a {RegistryUpdated} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function updateRegistry(address _registry) external;

    // @dev Updates the treasury address and emits a {TreasuryUpdated} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function updateTreasury(address payable _treasury) external;

    // @dev Updates the percent fee and emits a {PercentFeeUpdated} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function updatePercentFee(uint256 _percentFee) external;

    // @dev Updates the base fee and emits a {BaseFeeUpdated} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function updateBaseFee(uint256 _baseFee) external;

    // @dev Adds a strategy to the cloneable strategies mapping and emits a {StrategyApproved} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function addToCloneableStrategies(address _strategy) external;

    // @dev Removes a strategy from the cloneable strategies mapping and emits a {StrategyRemoved} event
    //
    // Requirements: 'msg.sender' must be the allo contract owner
    //
    function removeFromCloneableStrategies(address _strategy) external;

    // @dev Adds a pool manager to the pool and emits {RoleGranted} event
    //
    // Requirements: 'msg.sender' must be a pool admin
    //
    function addPoolManager(uint256 _poolId, address _manager) external;

    // @dev Removes a pool manager from the pool and emits {RoleRevoked} event
    //
    // Requirements: 'msg.sender' must be a pool admin
    //
    function removePoolManager(uint256 _poolId, address _manager) external;

    // @dev Recovers funds from a pool
    //
    /// Requirements: 'msg.sender' must be a pool admin
    ///
    function recoverFunds(address _token, address _recipient) external;

    /// @dev Registers a recipient and emits {Registered} event if successful and may be handled differently by each strategy
    ///
    /// Requirements: determined by the strategy
    ///
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address);

    /// @dev Registers a batch of recipients and emits {Registered} event if successful for each recipient
    ///      and may be handled differently by each strategy
    ///
    /// Requirements: determined by the strategy
    ///
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory);

    /// @dev Funds a pool and emits {PoolFunded} event if successful
    ///
    /// Requirements: None, but 'msg.value' must be greater than 0 if the token is the native token
    ///               or '_amount' must be greater than 0 if the token is not the native token
    ///
    function fundPool(uint256 _poolId, uint256 _amount) external payable;

    /// @dev Allocates funds to a recipient and emits {Allocated} event if successful
    ///
    /// Note: Each strategy will handle the allocation of funds differently
    function allocate(uint256 _poolId, bytes memory _data) external payable;

    /// @dev Allocates funds to multiple recipients and emits {Allocated} event if successful for each recipient
    ///
    /// Note: Each strategy will handle the allocation of funds differently
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external;

    /// @dev Distributes funds to recipients and emits {Distributed} event if successful
    ///
    /// Note: Each strategy will handle the distribution of funds differently
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @dev Checks if an address is a pool admin and returns a boolean
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);

    /// @dev Checks if an address is a pool manager and returns a boolean
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool);

    /// @dev Checks if a strategy is cloneable (is in the cloneableStrategies mapping) and returns a boolean
    function isCloneableStrategy(address) external view returns (bool);

    /// @dev Returns the address of the strategy for a given 'poolId'
    function getStrategy(uint256 _poolId) external view returns (address);

    /// @dev Returns the current percent fee
    function getPercentFee() external view returns (uint256);

    /// @dev Returns the current base fee
    function getBaseFee() external view returns (uint256);

    /// @dev Returns the current treasury address
    function getTreasury() external view returns (address payable);

    /// @dev Returns the current registry address
    function getRegistry() external view returns (IRegistry);

    /// @dev Returns the 'Pool' struct for a given 'poolId'
    function getPool(uint256) external view returns (Pool memory);

    /// @dev Returns the current fee denominator - set at 1e18 to represent 100%
    function getFeeDenominator() external view returns (uint256);
}
