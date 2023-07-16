// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IStrategy} from "../strategies/IStrategy.sol";
import {IRegistry} from "./IRegistry.sol";
import {Metadata} from "./libraries/Metadata.sol";

interface IAllo {
    /// ======================
    /// ======= Structs ======
    /// ======================
    struct Pool {
        bytes32 identityId;
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
    error INVALID_TOKEN();

    /// ======================
    /// ======= Events =======
    /// ======================
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);
    event PoolTotalFundingDecreased(uint256 indexed poolId, uint256 prevAmount, uint256 newAmount);
    event TreasuryUpdated(address treasury);
    event FeePercentageUpdated(uint256 feePercentage);
    event BaseFeeUpdated(uint256 baseFee);
    event RegistryUpdated(address registry);
    event StrategyApproved(address strategy);
    event StrategyRemoved(address strategy);
    event FeeSkirtingBountyPercentageUpdated(uint256 feeSkirtingBountyPercentage);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    function initialize(
        address _registry,
        address payable _treasury,
        uint256 _feePercentage,
        uint256 _baseFee,
        uint256 _feeSkirtingBountyPercentage
    ) external;

    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external;
    function updateRegistry(address _registry) external;
    function updateTreasury(address payable _treasury) external;
    function updateFeePercentage(uint256 _feePercentage) external;
    function updateBaseFee(uint256 _baseFee) external;
    function updateFeeSkirtingBountyPercentage(uint256 _feeSkirtingBountyPercentage) external;
    function addToApprovedStrategies(address _strategy) external;
    function removeFromApprovedStrategies(address _strategy) external;
    function addPoolManager(uint256 _poolId, address _manager) external;
    function removePoolManager(uint256 _poolId, address _manager) external;
    function recoverFunds(address _token, address _recipient) external;
    function decreasePoolTotalFunding(uint256 _poolId, uint256 _amountToDecrease) external;
    function registerRecipients(uint256 _poolId, bytes memory _data) external payable returns (address);
    function fundPool(uint256 _poolId, uint256 _amount, address _token) external payable;
    function allocate(uint256 _poolId, bytes memory _data) external payable;
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external;
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;

    /// =========================
    /// ==== View Functions =====
    /// =========================

    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool);
    function isApprovedStrategies(address) external view returns (bool);

    function getStrategy(uint256 _poolId) external view returns (address);
    function getFeePercentage() external view returns (uint256);
    function getBaseFee() external view returns (uint256);
    function getTreasury() external view returns (address payable);
    function getRegistry() external view returns (IRegistry);
    function getFeeSkirtingBountyPercentage() external view returns (uint256);
    function getPool(uint256) external view returns (Pool memory);

    function FEE_DENOMINATOR() external view returns (uint256);
}
