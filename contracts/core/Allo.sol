// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@solady/auth/Ownable.sol";

import {Metadata} from "./libraries/Metadata.sol";
import {Clone} from "./libraries/Clone.sol";
import "../interfaces/IAllocationStrategy.sol";
import "../interfaces/IDistributionStrategy.sol";
import "./Registry.sol";

contract Allo is Initializable, Ownable, MulticallUpgradeable {
    error NO_ACCESS_TO_ROLE();
    error INVALID_FEE_PERCENTAGE();
    error TRANSFER_FAILED();
    error NOT_ENOUGH_FUNDS();

    /// @notice Struct to hold details of an Pool
    struct Pool {
        bytes32 identityId;
        IAllocationStrategy allocationStrategy;
        IDistributionStrategy distributionStrategy;
        Metadata metadata;
    }

    uint24 public constant DENOMINATOR = 100000;

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Fee percentage
    /// @dev 100% = 100_000 | 10% = 10_000 | 1% = 1_000 | 0.1% = 100 | 0.01% = 10
    uint24 public feePercentage;

    /// @notice Incremental index
    uint256 private _poolIndex;

    /// @notice Nonce to create salt for clone strategy
    uint256 private _nonce;

    /// @notice Allo treasury
    address payable public treasury;

    /// @notice Registry of pool creators
    Registry public registry;

    /// @notice Pool.id -> Pool
    mapping(uint256 => Pool) public pools;

    /// ======================
    /// ======= Events =======
    /// ======================

    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        address allocationStrategy,
        address distributionStrategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeeUpdated(uint256 fee);

    event RegistryUpdated(address registry);

    /// ====================================
    /// =========== Intializer =============
    /// ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> an higher version should be passed to reinitializer
    /// @param _registry The address of the registry
    function initialize(address _registry) public reinitializer(1) {
        _initializeOwner(msg.sender);

        registry = Registry(_registry);

        __Multicall_init();
    }

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    modifier isPoolMember(uint256 _poolId) {
        registry.isMemberOfIdentity(pools[_poolId].identityId, msg.sender);
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Fetch pool and identityMetadata
    /// @param _poolId The id of the pool
    /// @dev calls out to the registry to get the identity metadata
    function getPoolInfo(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }

    /// @notice Creates a new pool
    /// @param _identityId The identityId of the pool creator in the registry
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The metadata of the pool
    function createPool(
        bytes32 _identityId,
        address _allocationStrategy,
        address payable _distributionStrategy,
        address _token,
        uint256 _amount,
        Metadata memory _metadata
    ) external payable returns (uint256 poolId) {
        if (!registry.isOwnerOrMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        Pool memory pool = Pool({
            identityId: _identityId,
            allocationStrategy: IAllocationStrategy(Clone.createClone(_allocationStrategy, _nonce)),
            distributionStrategy: IDistributionStrategy(Clone.createClone(_distributionStrategy, _nonce)),
            metadata: _metadata
        });

        // Note: Only fund the pool on creation if the amount is greater than 0
        if (_amount > 0) {
            _deductFeeAndTransfer(_token, _amount, pool);
        }

        poolId = _poolIndex++;
        pools[poolId] = pool;

        emit PoolCreated(poolId, _identityId, _allocationStrategy, _distributionStrategy, _token, _amount, _metadata);

        return poolId;
    }

    /// @notice passes _data through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function applyToPool(uint256 _poolId, bytes memory _data) external payable returns (bytes memory) {
        IAllocationStrategy allocationStrategy = pools[_poolId].allocationStrategy;

        return allocationStrategy.applyToPool(_data, msg.sender);
    }

    /// @notice Update pool metadata
    /// @param _poolId id of the pool
    /// @param _metadata new metadata of the pool
    /// @dev Only callable by the pool member
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata)
        external
        payable
        isPoolMember(_poolId)
        returns (bytes memory)
    {
        Pool storage pool = pools[_poolId];
        pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);

        return abi.encode(pool);
    }

    /// @notice Fund a pool
    /// @param _poolId id of the pool
    /// @param _amount extra amount of the token to be deposited into the pool
    /// @param _token The address of the token that the pool is denominated in
    function fundPool(uint256 _poolId, uint256 _amount, address _token) external payable {
        if (_amount <= 0) {
            revert NOT_ENOUGH_FUNDS();
        }

        Pool storage pool = pools[_poolId];

        _deductFeeAndTransfer(_token, _amount, pool);

        emit PoolFunded(_poolId, _amount);
    }

    /// @notice passes _data & msg.sender through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        pools[_poolId].allocationStrategy.allocate(_data, msg.sender);
    }

    /// @notice Finalizes a pool
    /// @param _poolId id of the pool
    /// @param _dataFromPoolOwner encoded data unique to the pool owner
    /// @dev Only callable by the pool member
    ///
    /// calls voting.generatePayouts() and then uses return data for payout.activatePayouts()
    /// check to make sure they haven't skrited around fee
    function finalize(uint256 _poolId, bytes calldata _dataFromPoolOwner) external isPoolMember(_poolId) {
        // ASK: Do we need _dataFromPoolOwner to allow owner to pass custom data ?
        Pool memory pool = pools[_poolId];
        bytes memory dataFromAllocationStrategy = pool.allocationStrategy.generatePayouts();

        pool.distributionStrategy.activateDistribution(dataFromAllocationStrategy, _dataFromPoolOwner);
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the distributionStrategy strategy for that pool
    /// @dev Only callable by the pool member
    function distribute(uint256 _poolId, bytes memory _data) external isPoolMember(_poolId) {
        pools[_poolId].distributionStrategy.distribute(_data, msg.sender);
    }

    /// @notice Updates the registry address
    /// @param _registry The new registry address
    /// @dev Only callable by the owner if the current registry cannot be used
    function updateRegistry(address _registry) external onlyOwner {
        registry = Registry(_registry);
        emit RegistryUpdated(_registry);
    }

    /// @notice Updates the treasury address
    /// @param _treasury The new treasury address
    /// @dev Only callable by the owner
    function updateTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(treasury);
    }

    /// @notice Updates the fee percentage
    /// @param _feePercentage The new fee
    /// @dev Only callable by the owner
    function updateFee(uint24 _feePercentage) external onlyOwner {
        if (_feePercentage > DENOMINATOR) {
            revert INVALID_FEE_PERCENTAGE();
        }

        feePercentage = _feePercentage;

        emit FeeUpdated(feePercentage);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Deduct the fee and transfers the amount to the distribution strategy
    /// @param _token The address of the token to transfer
    /// @param _amount The amount to transfer
    /// @param _pool The pool to transfer to
    function _deductFeeAndTransfer(address _token, uint256 _amount, Pool memory _pool) internal {
        uint256 feeAmount = (_amount * feePercentage) / DENOMINATOR;

        // Pay the protocol fee
        _transferAmount(treasury, _amount, _token);

        // Send the remaining amount to the distribution strategy
        uint256 amountAfterFee = _amount - feeAmount;
        _transferAmount(payable(address(_pool.distributionStrategy)), amountAfterFee, _token);
    }

    /// @notice Transfers the amount to the address
    /// @param _to The address to transfer to
    /// @param _amount The amount to transfer
    /// @param _token The address of the token to transfer
    function _transferAmount(address payable _to, uint256 _amount, address _token) internal {
        if (_token == address(0)) {
            // Native Token
            (bool sent,) = _to.call{value: _amount}("");
            if (!sent) {
                revert TRANSFER_FAILED();
            }
        } else {
            // ERC20 Token
            IERC20Upgradeable(_token).transfer(_to, _amount);
        }
    }
}
