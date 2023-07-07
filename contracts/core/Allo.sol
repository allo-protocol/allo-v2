// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import "@solady/auth/Ownable.sol";

import {Metadata} from "./libraries/Metadata.sol";
import {Clone} from "./libraries/Clone.sol";
import "../interfaces/IAllocationStrategy.sol";
import "../interfaces/IDistributionStrategy.sol";
import "./Registry.sol";

contract Allo is Initializable, Ownable, AccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Custom errors
    error UNAUTHORIZED();
    error TRANSFER_FAILED();
    error NOT_ENOUGH_FUNDS();
    error NOT_APPROVED_STRATEGY();

    /// @notice Struct to hold details of an Pool
    struct Pool {
        bytes32 identityId;
        IAllocationStrategy allocationStrategy;
        IDistributionStrategy distributionStrategy;
        Metadata metadata;
        bytes32 managerRole;
        bytes32 adminRole;
    }

    /// @notice Fee denominator
    uint256 public constant FEE_DENOMINATOR = 1e18;

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Fee percentage
    /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 public feePercentage;

    /// @notice Base fee
    uint256 public baseFee;

    /// @notice Incremental index
    uint256 private _poolIndex;

    /// @notice msg.sender -> nonce for cloning strategies
    mapping(address => uint256) private _nonces;

    /// @notice Allo treasury
    address payable public treasury;

    /// @notice Registry of pool creators
    Registry public registry;

    /// @notice Pool.id -> Pool
    mapping(uint256 => Pool) public pools;

    /// @notice Strategy -> bool
    mapping(address => bool) public approvedStrategies;

    /// ======================
    /// ======= Events =======
    /// ======================

    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        IAllocationStrategy allocationStrategy,
        IDistributionStrategy distributionStrategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeePercentageUpdated(uint256 feePercentage);

    event BaseFeeUpdated(uint256 baseFee);

    event RegistryUpdated(address registry);

    /// ====================================
    /// =========== Intializer =============
    /// ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> an higher version should be passed to reinitializer
    /// @param _registry The address of the registry
    /// @param _treasury The address of the treasury
    /// @param _feePercentage The fee percentage
    /// @param _baseFee The base fee
    function initialize(address _registry, address payable _treasury, uint256 _feePercentage, uint256 _baseFee)
        public
        reinitializer(1)
    {
        _initializeOwner(msg.sender);

        registry = Registry(_registry);
        treasury = _treasury;
        feePercentage = _feePercentage;
        baseFee = _baseFee;

        emit RegistryUpdated(_registry);
        emit TreasuryUpdated(_treasury);
        emit FeePercentageUpdated(_feePercentage);
        emit BaseFeeUpdated(_baseFee);
    }

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Checks if the msg sender is the pool owner
    modifier onlyPoolOwner(uint256 _poolId) {
        if (!hasRole(keccak256(abi.encodePacked(_poolId)), msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Checks if the msg sender is a pool admin
    modifier onlyPoolAdmin(uint256 _poolId) {
        if (!_isPoolAdmin(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Checks if the msg sender is a pool manager
    modifier onlyPoolManager(uint256 _poolId) {
        if (!_isPoolManager(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Creates a new pool (with clone for approved strategies)
    /// @param _identityId The identityId of the pool
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _initAllocationData The data to initialize the allocation strategy
    /// @param _cloneAllocationStrategy Whether to clone the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _initDistributionData The data to initialize the distribution strategy
    /// @param _cloneDistributionStrategy Whether to clone the distribution strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    function createPoolWithClone(
        bytes32 _identityId,
        address _allocationStrategy,
        bytes memory _initAllocationData,
        bool _cloneAllocationStrategy,
        address _distributionStrategy,
        bytes memory _initDistributionData,
        bool _cloneDistributionStrategy,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
        address allocationStrategy;
        address distributionStrategy;

        // DISCUSS: We either
        // - allow cloning of every contract (use the bool)
        // - or we force cloning of only approved contracts

        if (_cloneAllocationStrategy) {
            if (!_isApprovedStrategy(_allocationStrategy)) {
                revert NOT_APPROVED_STRATEGY();
            }
            allocationStrategy = Clone.createClone(_allocationStrategy, _nonces[msg.sender]++);
        } else {
            allocationStrategy = _allocationStrategy;
        }

        if (_cloneDistributionStrategy) {
            if (!_isApprovedStrategy(_distributionStrategy)) {
                revert NOT_APPROVED_STRATEGY();
            }
            distributionStrategy = Clone.createClone(_distributionStrategy, _nonces[msg.sender]++);
        } else {
            distributionStrategy = _distributionStrategy;
        }

        return _createPool(
            _identityId,
            IAllocationStrategy(allocationStrategy),
            _initAllocationData,
            IDistributionStrategy(distributionStrategy),
            _initDistributionData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    /// @notice Creates a new pool
    /// @param _identityId The identityId of the pool creator in the registry
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _initAllocationData The data to initialize the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _initDistributionData The data to initialize the distribution strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The metadata of the pool
    /// @param _managers The _managers of the pool
    function createPool(
        bytes32 _identityId,
        address _allocationStrategy,
        bytes memory _initAllocationData,
        address _distributionStrategy,
        bytes memory _initDistributionData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
        return _createPool(
            _identityId,
            IAllocationStrategy(_allocationStrategy),
            _initAllocationData,
            IDistributionStrategy(_distributionStrategy),
            _initDistributionData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    /// @notice Creates a new pool
    /// @param _identityId The identityId of the pool creator in the registry
    /// @param _allocationStrategy The address of the allocation strategy
    /// @param _distributionStrategy The address of the distribution strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    function _createPool(
        bytes32 _identityId,
        IAllocationStrategy _allocationStrategy,
        bytes memory _initAllocationData,
        IDistributionStrategy _distributionStrategy,
        bytes memory _initDistributionData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal returns (uint256 poolId) {
        if (!registry.isOwnerOrMemberOfIdentity(_identityId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        // access control
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        Pool memory pool = Pool({
            identityId: _identityId,
            allocationStrategy: _allocationStrategy,
            distributionStrategy: _distributionStrategy,
            metadata: _metadata,
            managerRole: POOL_MANAGER_ROLE,
            adminRole: POOL_ADMIN_ROLE
        });

        poolId = ++_poolIndex;
        pools[poolId] = pool;

        // grant admin roles to pool creator
        _grantRole(POOL_ADMIN_ROLE, msg.sender);
        // set admin role for POOL_MANAGER_ROLE
        _setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);

        // initialize strategies
        // @dev Initialization is expect to revert when invoked more than once
        _allocationStrategy.initialize(address(this), _identityId, poolId, _initAllocationData);
        _distributionStrategy.initialize(address(this), _identityId, poolId, _token, _initDistributionData);

        // grant pool managers roles
        uint256 managersLength = _managers.length;
        for (uint256 i = 0; i < managersLength;) {
            _grantRole(POOL_MANAGER_ROLE, _managers[i]);
            unchecked {
                i++;
            }
        }

        if (baseFee > 0) {
            _transferAmount(treasury, baseFee, address(0));
            emit BaseFeePaid(poolId, baseFee);
        }

        if (_amount > 0) {
            _fundPool(_token, _amount, poolId, _distributionStrategy);
        }

        emit PoolCreated(poolId, _identityId, _allocationStrategy, _distributionStrategy, _token, _amount, _metadata);
    }

    /// @notice passes _data through to the allocation strategy for that pool
    /// @notice returns the applicationId from the allocation strategy
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function addRecipient(uint256 _poolId, bytes memory _data) external payable returns (uint256) {
        return pools[_poolId].allocationStrategy.addRecipient(_data, msg.sender);
    }

    /// @notice Update pool metadata
    /// @param _poolId id of the pool
    /// @param _metadata new metadata of the pool
    /// @dev Only callable by the pool managers
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external onlyPoolManager(_poolId) {
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

        _fundPool(_token, _amount, _poolId, pools[_poolId].distributionStrategy);
    }

    /// @notice passes _data & msg.sender through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        _allocate(_poolId, _data);
    }

    /// @notice allocate to multiple pools
    /// @param _poolIds ids of the pools
    /// @param _datas encoded data unique to the allocation strategy for that pool
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external payable {
        for (uint256 i = 0; i < _poolIds.length;) {
            _allocate(_poolIds[i], _datas[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the distributionStrategy strategy for that pool
    function distribute(uint256 _poolId, uint256[] memory _applicationIds, bytes memory _data) external {
        pools[_poolId].distributionStrategy.distribute(_applicationIds, _data, msg.sender);
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
        feePercentage = _feePercentage;

        emit FeePercentageUpdated(feePercentage);
    }

    /// @notice Add a strategy to the allowlist
    /// @param _strategy The address of the strategy
    /// @dev Only callable by the owner
    function addToApprovedStrategies(address _strategy) external onlyOwner {
        approvedStrategies[_strategy] = true;
    }

    /// @notice Remove a strategy from the allowlist
    /// @param _strategy The address of the strategy
    /// @dev Only callable by the owner
    function removeFromApprovedStrategies(address _strategy) external onlyOwner {
        approvedStrategies[_strategy] = false;
    }

    /// @notice Updates the base fee
    /// @param _baseFee The new base fee
    /// @dev Only callable by the owner
    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
        emit BaseFeeUpdated(baseFee);
    }

    /// @notice Checks if the address is a pool admin
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolAdmin(_poolId, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolManager(_poolId, _address);
    }

    /// @notice Add a pool manager
    /// @param _poolId The pool id
    /// @param _manager The address to add
    function addPoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        _grantRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Remove a pool manager
    /// @param _poolId The pool id
    /// @param _manager The address remove
    function removePoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        _revokeRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Return the allocation strategy for a pool
    /// @param _poolId The pool id
    /// @return address
    function getAllocationStrategy(uint256 _poolId) external view returns (address) {
        return address(pools[_poolId].allocationStrategy);
    }

    /// @notice Return the distribution strategy for a pool
    /// @param _poolId The pool id
    /// @return address
    function getDistributionStrategy(uint256 _poolId) external view returns (address) {
        return address(pools[_poolId].distributionStrategy);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice passes _data & msg.sender through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function _allocate(uint256 _poolId, bytes memory _data) internal {
        pools[_poolId].allocationStrategy.allocate{value: msg.value}(_data, msg.sender);
    }

    /// @notice Deduct the fee and transfers the amount to the distribution strategy
    /// @param _token The address of the token to transfer
    /// @param _amount The amount to transfer
    /// @param _poolId The pool id
    /// @param _distributionStrategy The address of the distribution strategy
    function _fundPool(address _token, uint256 _amount, uint256 _poolId, IDistributionStrategy _distributionStrategy)
        internal
    {
        uint256 feeAmount = (_amount * feePercentage) / FEE_DENOMINATOR;

        // Pay the protocol fee
        _transferAmount(treasury, feeAmount, _token);

        // Send the remaining amount to the distribution strategy
        uint256 amountAfterFee = _amount - feeAmount;
        _transferAmount(payable(address(_distributionStrategy)), amountAfterFee, _token);
        _distributionStrategy.poolFunded(amountAfterFee);

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
            IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        }
    }

    /// @notice Checks if the strategy is approved
    /// @param _strategy The address of the strategy
    function _isApprovedStrategy(address _strategy) internal view returns (bool) {
        return approvedStrategies[_strategy];
    }

    /// @notice Checks if the address is a pool admin
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool
    function _isPoolAdmin(uint256 _poolId, address _address) internal view returns (bool) {
        return hasRole(pools[_poolId].adminRole, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool
    function _isPoolManager(uint256 _poolId, address _address) internal view returns (bool) {
        return hasRole(pools[_poolId].managerRole, _address);
    }
}
