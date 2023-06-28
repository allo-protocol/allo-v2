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
    error STRATEGY_ALREADY_USED();
    error STRATEGY_NOT_APPROVED();

    /// @notice Struct to hold details of an Pool
    struct Pool {
        bytes32 identityId;
        IAllocationStrategy allocationStrategy;
        IDistributionStrategy distributionStrategy;
        Metadata metadata;
    }

    uint256 public constant FEE_DENOMINATOR = 1e18;

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Fee percentage
    /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 public feePercentage;

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

    /// @notice Strategy -> bool
    mapping(address => bool) public approvedStrategies;

    /// @notice Strategy -> bool
    mapping(address => bool) public usedStrategies;

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

    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

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
    /// @param _treasury The address of the treasury
    /// @param _feePercentage The fee percentage
    function initialize(address _registry, address payable _treasury, uint256 _feePercentage) public reinitializer(1) {
        _initializeOwner(msg.sender);

        registry = Registry(_registry);
        treasury = _treasury;
        feePercentage = _feePercentage;

        emit RegistryUpdated(_registry);
        emit TreasuryUpdated(_treasury);
        emit FeeUpdated(_feePercentage);

        __Multicall_init();
    }

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    modifier isPoolAdmin(uint256 _poolId) {
        if (!registry.isOwnerOrMemberOfIdentity(pools[_poolId].identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Returns the pool info
    /// @param _poolId The id of the pool
    /// @dev calls out to the registry to get the identity metadata
    function getPoolInfo(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }

    /// @notice Creates a new pool (with clone)
    /// @param _identityId The identityId of the pool
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _cloneAllocationStrategy Boolean flag to clone the allocation strategy
    /// @param _cloneDistributionStrategy Boolean flag to clone the distribution strategy
    function createPoolWithClone(
        bytes32 _identityId,
        address _allocationStrategy,
        address payable _distributionStrategy,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        bool _cloneAllocationStrategy,
        bool _cloneDistributionStrategy
    ) external payable returns (uint256 poolId) {
        // Note: I added both options here to see what we wanted to go with.
        if (_cloneAllocationStrategy && !_isApprovedStrategy(_allocationStrategy)) {
            revert STRATEGY_NOT_APPROVED();
            // require(_isApprovedStrategy(_allocationStrategy), "STRATEGY_NOT_APPROVED");
        }

        if (_cloneDistributionStrategy && !_isApprovedStrategy(_distributionStrategy)) {
            revert STRATEGY_NOT_APPROVED();
            // require(_isApprovedStrategy(_distributionStrategy), "STRATEGY_NOT_APPROVED");
        }

        address allocationStrategy =
            _cloneAllocationStrategy ? Clone.createClone(_allocationStrategy, _nonce++) : _allocationStrategy;

        address distributionStrategy =
            _cloneDistributionStrategy ? Clone.createClone(_distributionStrategy, _nonce++) : _distributionStrategy;

        return _createPool(_identityId, allocationStrategy, payable(distributionStrategy), _token, _amount, _metadata);
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
        return _createPool(_identityId, _allocationStrategy, _distributionStrategy, _token, _amount, _metadata);
    }

    /// @notice Creates a new pool
    /// @param _identityId The identityId of the pool creator in the registry
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The metadata of the pool
    function _createPool(
        bytes32 _identityId,
        address _allocationStrategy,
        address payable _distributionStrategy,
        address _token,
        uint256 _amount,
        Metadata memory _metadata
    ) internal returns (uint256 poolId) {
        if (!registry.isOwnerOrMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        if (usedStrategies[_allocationStrategy] || usedStrategies[_distributionStrategy]) {
            revert STRATEGY_ALREADY_USED();
        }

        usedStrategies[_allocationStrategy] = true;
        usedStrategies[_distributionStrategy] = true;

        Pool memory pool = Pool({
            identityId: _identityId,
            allocationStrategy: IAllocationStrategy(_allocationStrategy),
            distributionStrategy: IDistributionStrategy(_distributionStrategy),
            metadata: _metadata
        });

        poolId = ++_poolIndex;

        if (_amount > 0) {
            _fundPool(_token, _amount, poolId, address(pool.distributionStrategy));
        }

        pools[poolId] = pool;

        emit PoolCreated(poolId, _identityId, _allocationStrategy, _distributionStrategy, _token, _amount, _metadata);
    }

    /// @notice passes _data through to the allocation strategy for that pool
    /// @notice returns the applicationId from the allocation strategy
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function applyToPool(uint256 _poolId, bytes memory _data) external payable returns (uint256) {
        IAllocationStrategy allocationStrategy = pools[_poolId].allocationStrategy;

        return allocationStrategy.applyToPool(_data, msg.sender);
    }

    /// @notice Update pool metadata
    /// @param _poolId id of the pool
    /// @param _metadata new metadata of the pool
    /// @dev Only callable by the pool admin
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external isPoolAdmin(_poolId) {
        Pool storage pool = pools[_poolId];
        pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    /// @notice Fund a pool
    /// @param _poolId id of the pool
    /// @param _amount extra amount of the token to be deposited into the pool
    /// @param _token The address of the token that the pool is denominated in
    /// @dev Anyone can fund a pool
    function fundPool(uint256 _poolId, uint256 _amount, address _token) external payable {
        if (_amount == 0) {
            revert NOT_ENOUGH_FUNDS();
        }

        _fundPool(_token, _amount, _poolId, address(pools[_poolId].distributionStrategy));
    }

    /// @notice passes _data & msg.sender through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        pools[_poolId].allocationStrategy.allocate{value: msg.value}(_data, msg.sender);
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the distributionStrategy strategy for that pool
    function distribute(uint256 _poolId, bytes memory _data) external {
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
    function updateFee(uint256 _feePercentage) external onlyOwner {
        if (_feePercentage > FEE_DENOMINATOR) {
            revert INVALID_FEE_PERCENTAGE();
        }

        feePercentage = _feePercentage;

        emit FeeUpdated(feePercentage);
    }

    /// @notice Add a strategy to the allowlist
    /// @param _strategy The address of the strategy
    function addToApprovedStrategies(address _strategy) external onlyOwner {
        approvedStrategies[_strategy] = true;
        usedStrategies[_strategy] = true;
    }

    /// @notice Remove a strategy from the allowlist
    /// @param _strategy The address of the strategy
    function removeFromApprovedStrategies(address _strategy) external onlyOwner {
        approvedStrategies[_strategy] = false;
    }

    /// @notice Add a strategy to the used list
    /// @param _strategy The address of the strategy
    function addToUsedStrategies(address _strategy) external onlyOwner {
        usedStrategies[_strategy] = true;
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Deduct the fee and transfers the amount to the distribution strategy
    /// @param _token The address of the token to transfer
    /// @param _amount The amount to transfer
    /// @param _poolId The pool id
    /// @param _distributionStrategy The address of the distribution strategy
    function _fundPool(address _token, uint256 _amount, uint256 _poolId, address _distributionStrategy) internal {
        uint256 feeAmount = (_amount * feePercentage) / FEE_DENOMINATOR;

        // Pay the protocol fee
        _transferAmount(treasury, feeAmount, _token);

        // Send the remaining amount to the distribution strategy
        uint256 amountAfterFee = _amount - feeAmount;
        _transferAmount(payable(_distributionStrategy), amountAfterFee, _token);

        emit PoolFunded(_poolId, amountAfterFee, feeAmount);
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

    /// @notice Checks if the strategy is approved
    /// @param _strategy The address of the strategy
    function _isApprovedStrategy(address _strategy) internal view returns (bool) {
        return approvedStrategies[_strategy];
    }
}
