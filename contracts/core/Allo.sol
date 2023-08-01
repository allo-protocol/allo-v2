// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "solady/src/auth/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// Interfaces
import "./IAllo.sol";
// Internal Libraries
import {Clone} from "./libraries/Clone.sol";
import "./libraries/Native.sol";
import {Transfer} from "./libraries/Transfer.sol";

/**
 *          ___            ___        ___        ___
 *         /\  \          /\__\      /\__\      /\  \
 *        /::\  \        /:/  /     /:/  /     /::\  \
 *       /:/\:\  \      /:/  /     /:/  /     /:/\:\  \
 *      /::\~\:\  \    /:/  /     /:/  /     /:/  \:\  \
 *     /:/\:\ \:\__\  /:/__/     /:/__/     /:/__/ \:\__\
 *     \/__\:\/:/  /  \:\  \     \:\  \     \:\  \ /:/  /
 *          \::/  /    \:\  \     \:\  \     \:\  /:/  /
 *          /:/  /      \:\  \     \:\  \     \:\/:/  /
 *         /:/  /        \:\__\     \:\__\     \::/  /
 *         \/__/          \/__/      \/__/      \/__/
 */

/// @title Allo
/// @notice The Allo contract
/// @author allo-team
contract Allo is IAllo, Native, Transfer, Initializable, Ownable, AccessControl {
    /// @notice Fee denominator
    uint256 public constant FEE_DENOMINATOR = 1e18;

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Fee percentage
    /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 private feePercentage;

    /// @notice Base fee
    uint256 internal baseFee;

    /// @notice Incremental index
    uint256 private _poolIndex;

    /// @notice Allo treasury
    address payable private treasury;

    /// @notice Registry of pool creators
    IRegistry private registry;

    /// @notice msg.sender -> nonce for cloning strategies
    mapping(address => uint256) private _nonces;

    /// @notice Pool.id -> Pool
    // Note: the ProportionalPayout strategy needs this public?
    mapping(uint256 => Pool) private pools;

    /// @notice Strategy -> bool
    mapping(address => bool) private cloneableStrategies;

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
        external
        reinitializer(1)
    {
        _initializeOwner(msg.sender);

        _updateRegistry(_registry);
        _updateTreasury(_treasury);
        _updateFeePercentage(_feePercentage);
        _updateBaseFee(_baseFee);
    }

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    modifier onlyPoolManager(uint256 _poolId) {
        if (!_isPoolManager(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    modifier onlyPoolAdmin(uint256 _poolId) {
        if (!_isPoolAdmin(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Creates a new pool (with custom strategy)
    /// @param _profileId The profileId of the pool
    /// @param _strategy The address of strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    function createPoolWithCustomStrategy(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
        if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        if (_isCloneableStrategy(_strategy)) {
            revert IS_APPROVED_STRATEGY();
        }

        return _createPool(_profileId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
    }

    /// @notice Creates a new pool (by cloning a cloneable strategies)
    /// @param _profileId The profileId of the pool
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    function createPool(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
        if (!_isCloneableStrategy(_strategy)) {
            revert NOT_APPROVED_STRATEGY();
        }

        return _createPool(
            _profileId,
            IStrategy(Clone.createClone(_strategy, _nonces[msg.sender]++)),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
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

    /// @notice Updates the registry address
    /// @param _registry The new registry address
    /// @dev Only callable by the owner if the current registry cannot be used
    function updateRegistry(address _registry) external onlyOwner {
        _updateRegistry(_registry);
    }

    /// @notice Updates the treasury address
    /// @param _treasury The new treasury address
    /// @dev Only callable by the owner
    function updateTreasury(address payable _treasury) external onlyOwner {
        _updateTreasury(_treasury);
    }

    /// @notice Updates the fee percentage
    /// @param _feePercentage The new fee
    /// @dev Only callable by the owner
    function updateFeePercentage(uint256 _feePercentage) external onlyOwner {
        _updateFeePercentage(_feePercentage);
    }

    /// @notice Updates the base fee
    /// @param _baseFee The new base fee
    /// @dev Only callable by the owner
    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        _updateBaseFee(_baseFee);
    }

    /// @notice Add a strategy to the allowlist
    /// @param _strategy The address of the strategy
    /// @dev Only callable by the owner
    function addToCloneableStrategies(address _strategy) external onlyOwner {
        if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        cloneableStrategies[_strategy] = true;
        emit StrategyApproved(_strategy);
    }

    /// @notice Remove a strategy from the allowlist
    /// @param _strategy The address of the strategy
    /// @dev Only callable by the owner
    function removeFromCloneableStrategies(address _strategy) external onlyOwner {
        cloneableStrategies[_strategy] = false;
        emit StrategyRemoved(_strategy);
    }

    /// @notice Add a pool manager
    /// @param _poolId The pool id
    /// @param _manager The address to add
    function addPoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        if (_manager == address(0)) {
            revert ZERO_ADDRESS();
        }
        _grantRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Remove a pool manager
    /// @param _poolId The pool id
    /// @param _manager The address remove
    function removePoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        _revokeRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Transfer thefunds recovered  to the recipient
    /// @param _token The address of the token to transfer
    /// @param _recipient The address of the recipient
    function recoverFunds(address _token, address _recipient) external onlyOwner {
        uint256 amount = _token == NATIVE ? address(this).balance : IERC20Upgradeable(_token).balanceOf(address(this));
        _transferAmount(_token, _recipient, amount);
    }

    /// ====================================
    /// ======= Strategy Functions =========
    /// ====================================

    /// @notice passes _data through to the strategy for that pool
    /// @notice returns the recipientId from the strategy
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the strategy for that pool
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address) {
        return pools[_poolId].strategy.registerRecipient(_data, msg.sender);
    }

    /// @notice register to multiple pools
    /// @notice returns the recipientIds from the strategy
    /// @param _poolIds id of the pools
    /// @param _data encoded data unique to strategy for each pool
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory)
    {
        uint256 poolIdLength = _poolIds.length;
        address[] memory recipientIds = new address[](poolIdLength);

        if (poolIdLength != _data.length) {
            revert MISMATCH();
        }

        for (uint256 i = 0; i < poolIdLength;) {
            recipientIds[i] = pools[_poolIds[i]].strategy.registerRecipient(_data[i], msg.sender);
            unchecked {
                i++;
            }
        }

        return recipientIds;
    }

    /// @notice Fund a pool
    /// @param _poolId id of the pool
    /// @param _amount extra amount of the token to be deposited into the pool
    /// @dev Anyone can fund a pool
    function fundPool(uint256 _poolId, uint256 _amount) external payable {
        if (_amount == 0) {
            revert NOT_ENOUGH_FUNDS();
        }
        _fundPool(_amount, _poolId, pools[_poolId].strategy);
    }

    /// @notice passes _data & msg.sender through to the strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        _allocate(_poolId, _data);
    }

    /// @notice vote to multiple pools
    /// @param _poolIds ids of the pools
    /// @param _datas encoded data unique to the strategy for that pool
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external {
        uint256 numPools = _poolIds.length;
        if (numPools != _datas.length) {
            revert MISMATCH();
        }
        for (uint256 i = 0; i < numPools;) {
            _allocate(_poolIds[i], _datas[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the strategy for that pool
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external {
        pools[_poolId].strategy.distribute(_recipientIds, _data, msg.sender);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Creates a new pool
    /// @param _profileId The profileId of the pool creator in the registry
    /// @param _strategy The address of strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    function _createPool(
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal returns (uint256 poolId) {
        if (!registry.isOwnerOrMemberOfProfile(_profileId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        poolId = ++_poolIndex;

        // access control
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        Pool memory pool = Pool({
            profileId: _profileId,
            strategy: _strategy,
            metadata: _metadata,
            token: _token,
            managerRole: POOL_MANAGER_ROLE,
            adminRole: POOL_ADMIN_ROLE
        });

        pools[poolId] = pool;

        // grant admin roles to pool creator
        _grantRole(POOL_ADMIN_ROLE, msg.sender);
        // set admin role for POOL_MANAGER_ROLE
        _setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);

        // initialize strategies
        // @dev Initialization is expect to revert when invoked more than once
        _strategy.initialize(poolId, _initStrategyData);

        if (_strategy.getPoolId() != poolId || address(_strategy.getAllo()) != address(this)) {
            revert MISMATCH();
        }

        // grant pool managers roles
        uint256 managersLength = _managers.length;
        for (uint256 i = 0; i < managersLength;) {
            address manager = _managers[i];
            if (manager == address(0)) {
                revert ZERO_ADDRESS();
            }
            _grantRole(POOL_MANAGER_ROLE, manager);
            unchecked {
                i++;
            }
        }

        if (baseFee > 0) {
            // To prevent paying the baseFee from the Allo contract's balance
            // If _token is NATIVE, then baseFee + _amount should be >= than msg.value.
            // If _token is not NATIVE, then baseFee should be >= than msg.value.
            if ((_token == NATIVE && (baseFee + _amount >= msg.value)) || (_token != NATIVE && baseFee >= msg.value)) {
                revert NOT_ENOUGH_FUNDS();
            }
            _transferAmount(NATIVE, treasury, baseFee);
            emit BaseFeePaid(poolId, baseFee);
        }

        if (_amount > 0) {
            _fundPool(_amount, poolId, _strategy);
        }

        emit PoolCreated(poolId, _profileId, _strategy, _token, _amount, _metadata);
    }

    /// @notice passes _data & msg.sender through to the strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the strategy for that pool
    function _allocate(uint256 _poolId, bytes memory _data) internal {
        pools[_poolId].strategy.allocate{value: msg.value}(_data, msg.sender);
    }

    /// @notice Deduct the fee and transfers the amount to the distribution strategy
    /// @param _amount The amount to transfer
    /// @param _poolId The pool id
    /// @param _strategy The address of the strategy
    function _fundPool(uint256 _amount, uint256 _poolId, IStrategy _strategy) internal {
        uint256 feeAmount = 0;
        uint256 amountAfterFee = _amount;

        Pool storage pool = pools[_poolId];
        address _token = pool.token;

        if (feePercentage > 0) {
            feeAmount = (_amount * feePercentage) / FEE_DENOMINATOR;
            amountAfterFee -= feeAmount;

            _transferAmountFrom(_token, TransferData({from: msg.sender, to: treasury, amount: feeAmount}));
        }

        _transferAmountFrom(_token, TransferData({from: msg.sender, to: address(_strategy), amount: amountAfterFee}));
        _strategy.increasePoolAmount(amountAfterFee);

        emit PoolFunded(_poolId, amountAfterFee, feeAmount);
    }

    /// @notice Checks if the strategy is cloneable
    /// @param _strategy The address of the strategy
    function _isCloneableStrategy(address _strategy) internal view returns (bool) {
        return cloneableStrategies[_strategy];
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
        return hasRole(pools[_poolId].managerRole, _address) || _isPoolAdmin(_poolId, _address);
    }

    /// @notice Updates the registry address
    /// @param _registry The new registry address
    function _updateRegistry(address _registry) internal {
        if (_registry == address(0)) {
            revert ZERO_ADDRESS();
        }
        registry = IRegistry(_registry);
        emit RegistryUpdated(_registry);
    }

    /// @notice Updates the treasury address
    /// @param _treasury The new treasury address
    function _updateTreasury(address payable _treasury) internal {
        if (_treasury == address(0)) {
            revert ZERO_ADDRESS();
        }
        treasury = _treasury;
        emit TreasuryUpdated(treasury);
    }

    /// @notice Updates the fee percentage
    /// @param _feePercentage The new fee
    function _updateFeePercentage(uint256 _feePercentage) internal {
        if (_feePercentage > 1e18) {
            revert INVALID_FEE();
        }
        feePercentage = _feePercentage;

        emit FeePercentageUpdated(feePercentage);
    }

    /// @notice Updates the base fee
    /// @param _baseFee The new base fee
    function _updateBaseFee(uint256 _baseFee) internal {
        baseFee = _baseFee;
        emit BaseFeeUpdated(baseFee);
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

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

    /// @notice Return the strategy for a pool
    /// @param _poolId The pool id
    /// @return address
    function getStrategy(uint256 _poolId) external view returns (address) {
        return address(pools[_poolId].strategy);
    }

    /// @notice return fee percentage
    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }

    /// @notice return base fee
    function getBaseFee() external view returns (uint256) {
        return baseFee;
    }

    /// @notice return treasury
    function getTreasury() external view returns (address payable) {
        return treasury;
    }

    /// @notice return registry
    function getRegistry() external view returns (IRegistry) {
        return registry;
    }

    /// @notice return boolean if strategy is cloneable
    function isCloneableStrategy(address _strategy) external view returns (bool) {
        return _isCloneableStrategy(_strategy);
    }

    /// @notice return the pool
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }
}
