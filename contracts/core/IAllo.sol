// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IRegistry} from "./IRegistry.sol";
import {IStrategy} from "../strategies/IStrategy.sol";
// Internal Libraries
import {Metadata} from "./libraries/Metadata.sol";

interface IAllo {
    /// ======================
    /// ======= Structs ======
    /// ======================

    struct Pool {
        bytes32 profileId;
        IStrategy strategy;
        address token;
        uint256 amount;
        Metadata metadata;
        bytes32 managerRole;
        bytes32 adminRole;
    }

    /// ======================
    /// ======= Errors =======
    /// ======================

    error UNAUTHORIZED();
    error NOT_ENOUGH_FUNDS();
    error NOT_APPROVED_STRATEGY();
    error IS_APPROVED_STRATEGY();
    error MISMATCH();
    error ZERO_ADDRESS();
    error INVALID_FEE();

    /// ======================
    /// ======= Events =======
    /// ======================

    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);
    event TreasuryUpdated(address treasury);
    event FeePercentageUpdated(uint256 feePercentage);
    event BaseFeeUpdated(uint256 baseFee);
    event RegistryUpdated(address registry);
    event StrategyApproved(address strategy);
    event StrategyRemoved(address strategy);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    function initialize(address _registry, address payable _treasury, uint256 _feePercentage, uint256 _baseFee)
        external;

    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external;
    function updateRegistry(address _registry) external;
    function updateTreasury(address payable _treasury) external;
    function updateFeePercentage(uint256 _feePercentage) external;
    function updateBaseFee(uint256 _baseFee) external;
    function addToCloneableStrategies(address _strategy) external;
    function removeFromCloneableStrategies(address _strategy) external;
    function addPoolManager(uint256 _poolId, address _manager) external;
    function removePoolManager(uint256 _poolId, address _manager) external;
    function recoverFunds(address _token, address _recipient) external;
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address);
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory);
    function fundPool(uint256 _poolId, uint256 _amount) external payable;
    function allocate(uint256 _poolId, bytes memory _data) external payable;
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external;
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;

    /// =========================
    /// ==== View Functions =====
    /// =========================

    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool);
    function isCloneableStrategy(address) external view returns (bool);

    function getStrategy(uint256 _poolId) external view returns (address);
    function getFeePercentage() external view returns (uint256);
    function getBaseFee() external view returns (uint256);
    function getTreasury() external view returns (address payable);
    function getRegistry() external view returns (IRegistry);
    function getPool(uint256) external view returns (Pool memory);

    function FEE_DENOMINATOR() external view returns (uint256);
}
