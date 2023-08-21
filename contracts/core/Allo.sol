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

/// @title   ___            ___        ___        ___
///         /\  \          /\__\      /\__\      /\  \
///        /::\  \        /:/  /     /:/  /     /::\  \
///       /:/\:\  \      /:/  /     /:/  /     /:/\:\  \
///      /::\~\:\  \    /:/  /     /:/  /     /:/  \:\  \
///     /:/\:\ \:\__\  /:/__/     /:/__/     /:/__/ \:\__\
///     \/__\:\/:/  /  \:\  \     \:\  \     \:\  \ /:/  /
///          \::/  /    \:\  \     \:\  \     \:\  /:/  /
///          /:/  /      \:\  \     \:\  \     \:\/:/  /
///         /:/  /        \:\__\     \:\__\     \::/  /
///         \/__/          \/__/      \/__/      \/__/
///
/// @notice The Allo core contract
/// @dev This contract is used to create & manage pools as well as manage the protocol. It
///      is the core of all things Allo.
///
/// Requirements: The contract must be initialized with the 'initialize()' function
///
/// @author allo-team
contract Allo is IAllo, Native, Transfer, Initializable, Ownable, AccessControl {
    // ==========================
    // === Storage Variables ====
    // ==========================

    /// @notice Fee percentage
    /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 private percentFee;

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
    mapping(uint256 => Pool) private pools;

    /// @notice Strategy -> bool
    mapping(address => bool) private cloneableStrategies;

    // ====================================
    // =========== Intializer =============
    // ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> an higher version should be passed to reinitializer
    /// @param _registry The address of the registry
    /// @param _treasury The address of the treasury
    /// @param _percentFee The percentage fee
    /// @param _baseFee The base fee
    function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee)
        external
        reinitializer(1)
    {
        // Initialize the owner using Solady ownable library
        _initializeOwner(msg.sender);

        // Set the address of the registry
        _updateRegistry(_registry);

        // Set the address of the treasury
        _updateTreasury(_treasury);

        // Set the fee percentage
        _updatePercentFee(_percentFee);

        // Set the base fee
        _updateBaseFee(_baseFee);
    }

    // ====================================
    // =========== Modifier ===============
    // ====================================

    /// Both modifiers below are using OpenZeppelin's AccessControl.sol with custom roles under the hood

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool manager
    /// @param _poolId The pool id
    modifier onlyPoolManager(uint256 _poolId) {
        if (!_isPoolManager(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool admin
    /// @param _poolId The pool id
    modifier onlyPoolAdmin(uint256 _poolId) {
        if (!_isPoolAdmin(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Creates a new pool (with custom strategy)
    /// @dev 'msg.sender' must be a member or owner of a profile to create a pool with or without a custom strategy, The encoded data
    ///      will be specific to a given strategy requirements, reference the strategy implementation of 'initialize()'
    ///
    /// Requirements: The strategy address passed must not be a cloneable strategy
    ///               The strategy address passed must not be the zero address
    ///               'msg.sender' must be a member or owner of the profile id passed as '_profileId'
    ///
    /// @param _profileId The 'profileId' of the registry profile, used to check if 'msg.sender' is a member or owner of the profile
    /// @param _strategy The address of the deployed custom strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token you want to use in your pool
    /// @param _amount The amount of the token you want to deposit into the pool on initialization
    /// @param _metadata The 'Metadata' of the pool, this uses our 'Meatdata.sol' struct (consistent throughout the protocol)
    /// @param _managers The managers of the pool, and can be added/removed later by the pool admin
    /// @return poolId The id of the pool
    function createPoolWithCustomStrategy(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
        // Revert if the strategy address passed is the zero address with 'ZERO_ADDRESS()'
        if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        // Revert if we already have this strategy in our cloneable mapping with 'IS_APPROVED_STRATEGY()' (only non-cloneable strategies can be used)
        if (_isCloneableStrategy(_strategy)) {
            revert IS_APPROVED_STRATEGY();
        }

        // Call the internal '_createPool()' function and return the 'poolId'
        return _createPool(_profileId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
    }

    /// @notice Creates a new pool (by cloning a cloneable strategies)
    ///
    /// Requirements: 'msg.sender' must be owner or member of the profile id passed as '_profileId'
    ///
    /// @param _profileId The 'profileId' of the registry profile, used to check if 'msg.sender' is a member or owner of the profile
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    /// @custom:initstrategydata The encoded data will be specific to a given strategy requirements,
    ///    reference the strategy implementation of 'initialize()'
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

        // Returns the created pool id
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
    /// @dev Only callable by the pool managers, emits 'PoolMetadataUpdated()' event
    ///
    /// Requirements: The caller must be a pool manager
    ///
    /// @param _poolId id of the pool
    /// @param _metadata new metadata of the pool
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external onlyPoolManager(_poolId) {
        Pool storage pool = pools[_poolId];
        pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    /// @notice Updates the registry address
    /// @dev Use this to update the registry address
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _registry The new registry address
    function updateRegistry(address _registry) external onlyOwner {
        _updateRegistry(_registry);
    }

    /// @notice Updates the treasury address
    /// @dev Use this to update the treasury address
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _treasury The new treasury address
    function updateTreasury(address payable _treasury) external onlyOwner {
        _updateTreasury(_treasury);
    }

    /// @notice Updates the fee percentage
    /// @dev Use this to update the fee percentage
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _percentFee The new fee
    function updatePercentFee(uint256 _percentFee) external onlyOwner {
        _updatePercentFee(_percentFee);
    }

    /// @notice Updates the base fee
    /// @dev Use this to update the base fee
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _baseFee The new base fee
    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        _updateBaseFee(_baseFee);
    }

    /// @notice Add a strategy to the allowlist
    /// @dev Only callable by the owner, emits the 'StrategyApproved()' event
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _strategy The address of the strategy
    function addToCloneableStrategies(address _strategy) external onlyOwner {
        if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        cloneableStrategies[_strategy] = true;
        emit StrategyApproved(_strategy);
    }

    /// @notice Remove a strategy from the allowlist
    /// @dev Only callable by the owner, emits 'StrategyRemoved()' event
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _strategy The address of the strategy
    function removeFromCloneableStrategies(address _strategy) external onlyOwner {
        // Set the strategy to false in the cloneableStrategies mapping
        cloneableStrategies[_strategy] = false;

        // Emit the StrategyRemoved event
        emit StrategyRemoved(_strategy);
    }

    /// @notice Add a pool manager
    /// @dev emits 'RoleGranted()' event
    ///
    /// Requirements: The caller must be a pool admin
    ///
    /// @param _poolId The pool id
    /// @param _manager The address to add
    function addPoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        // Reverts if the address is the zero address with 'ZERO_ADDRESS()'
        if (_manager == address(0)) {
            revert ZERO_ADDRESS();
        }

        // Grants the pool manager role to the '_manager' address
        _grantRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Remove a pool manager
    /// @dev emits 'RoleRevoked()' event
    ///
    /// Requirements: The caller must be a pool admin
    ///
    /// @param _poolId The pool id
    /// @param _manager The address remove
    function removePoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        _revokeRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Transfer thefunds recovered  to the recipient
    ///
    /// Requirements: The caller must be Allo owner
    ///
    /// @param _token The address of the token to transfer
    /// @param _recipient The address of the recipient
    function recoverFunds(address _token, address _recipient) external onlyOwner {
        // Get the amount of the token to transfer, which is always the entire balance of the contract address
        uint256 amount = _token == NATIVE ? address(this).balance : IERC20Upgradeable(_token).balanceOf(address(this));

        // Transfer the amount to the recipient (pool owner)
        _transferAmount(_token, _recipient, amount);
    }

    // ====================================
    // ======= Strategy Functions =========
    // ====================================

    /// @notice Passes _data through to the strategy for that pool
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of registerRecipient()
    ///
    /// Requirements: This will be determined by the strategy
    ///
    /// @param _poolId Id of the pool
    /// @param _data Encoded data unique to a strategy that registerRecipient() requires
    /// @return recipientId The recipientId that has been registered
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address) {
        // Return the recipientId (address) from the strategy
        return pools[_poolId].strategy.registerRecipient(_data, msg.sender);
    }

    /// @notice Register multiple recipients to multiple pools
    /// @dev Returns the 'recipientIds' from the strategy that have been registered from calling this funciton
    ///      Encoded data unique to a strategy that registerRecipient() requires
    ///
    /// Requirements: Encoded '_data' length must match _poolIds length or this will revert with MISMATCH()
    ///               Other requirements will be determined by the strategy
    ///
    /// @param _poolIds Id of the pools
    /// @param _data An array of encoded data unique to a strategy that registerRecipient() requires
    /// @return recipientIds The recipientIds that have been registered
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory recipientIds)
    {
        uint256 poolIdLength = _poolIds.length;
        recipientIds = new address[](poolIdLength);

        if (poolIdLength != _data.length) {
            revert MISMATCH();
        }

        // Loop through the '_poolIds' & '_data' and call the 'strategy.registerRecipient()' function
        for (uint256 i = 0; i < poolIdLength;) {
            recipientIds[i] = pools[_poolIds[i]].strategy.registerRecipient(_data[i], msg.sender);
            unchecked {
                i++;
            }
        }

        // Return the recipientIds that have been registered
        return recipientIds;
    }

    /// @notice Fund a pool
    /// @dev Calls the internal _fundPool() function
    ///
    /// Requirements: None, anyone can fund a pool
    ///
    /// @param _poolId id of the pool
    /// @param _amount extra amount of the token to be deposited into the pool
    function fundPool(uint256 _poolId, uint256 _amount) external payable {
        // if amount is 0, revert with 'NOT_ENOUGH_FUNDS()' error
        if (_amount == 0) {
            revert NOT_ENOUGH_FUNDS();
        }

        // Call the internal fundPool() function
        _fundPool(_amount, _poolId, pools[_poolId].strategy);
    }

    /// @notice Passes '_data' & 'msg.sender' through to the strategy for that pool
    /// @dev Calls the 'strategy.allocate()' function with encoded '_data' defined by the strategy
    ///
    /// Requirements: This will be determined by the strategy
    ///
    /// @param _poolId Id of the pool
    /// @param _data Encoded data unique to the strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        _allocate(_poolId, _data);
    }

    /// @notice Allocate to multiple pools
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of allocate(). Please note that this is not a 'payable' function, so if you
    ///      want to send funds to the strategy, you must send the funds using 'fundPool()'
    ///
    /// Requirements: This will be determined by the strategy
    ///
    /// @param _poolIds ids of the pools
    /// @param _datas encoded data unique to the strategy for that pool
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external {
        uint256 numPools = _poolIds.length;

        // Reverts if the length of _poolIds does not match the length of _datas with 'MISMATCH()' error
        if (numPools != _datas.length) {
            revert MISMATCH();
        }

        // Loop through the _poolIds & _datas and call the internal _allocate() function
        for (uint256 i = 0; i < numPools;) {
            _allocate(_poolIds[i], _datas[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice passes '_data' & 'msg.sender' through to the disribution strategy for that pool
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of 'strategy.distribute()'
    ///
    /// Requirements: This will be determined by the strategy
    ///
    /// @param _poolId Id of the pool
    /// @param _data Encoded data unique to the strategy for that pool
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external {
        pools[_poolId].strategy.distribute(_recipientIds, _data, msg.sender);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Creates a new pool
    /// @dev This is an internal function that is called by the 'createPool()' & 'createPoolWithCustomStrategy()' functions
    ///      It is used to create a new pool and is called by both functions
    ///
    /// Requirements: The 'msg.sender' must be a member or owner of a profile to create a pool
    ///
    /// @param _profileId The 'profileId' of the pool creator in the registry
    /// @param _strategy The address of strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The 'Metadata' of the pool
    /// @param _managers The managers of the pool
    /// @return poolId The id of the pool
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

        // Generate the manager & admin roles for the pool (this is the way we do this throughout the protocol for consistency)
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        // Create the Pool instance
        Pool memory pool = Pool({
            profileId: _profileId,
            strategy: _strategy,
            metadata: _metadata,
            token: _token,
            managerRole: POOL_MANAGER_ROLE,
            adminRole: POOL_ADMIN_ROLE
        });

        // Add the pool to the mapping of created pools
        pools[poolId] = pool;

        // Grant admin roles to the pool creator
        _grantRole(POOL_ADMIN_ROLE, msg.sender);

        // Set admin role for POOL_MANAGER_ROLE
        _setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);

        // initialize strategies
        // Initialization is expected to revert when invoked more than once with 'BaseStrategy_ALREADY_INITIALIZED()' error
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

    /// @notice Allocate to recipient
    /// @dev Passes '_data' & 'msg.sender' through to the strategy for that pool
    ///      This is an internal function that is called by the 'allocate()' & 'batchAllocate()' functions
    ///
    /// @param _poolId Id of the pool
    /// @param _data Encoded data unique to the strategy for that pool
    function _allocate(uint256 _poolId, bytes memory _data) internal {
        pools[_poolId].strategy.allocate{value: msg.value}(_data, msg.sender);
    }

    /// @notice Fund a pool
    /// @dev Deducts the fee and transfers the amount to the distribution strategy
    ///
    /// @param _amount The amount to transfer
    /// @param _poolId The 'poolId' for the pool you are funding
    /// @param _strategy The address of the strategy
    function _fundPool(uint256 _amount, uint256 _poolId, IStrategy _strategy) internal {
        uint256 feeAmount = 0;
        uint256 amountAfterFee = _amount;

        Pool storage pool = pools[_poolId];
        address _token = pool.token;

        if (percentFee > 0) {
            feeAmount = (_amount * percentFee) / getFeeDenominator();
            amountAfterFee -= feeAmount;

            _transferAmountFrom(_token, TransferData({from: msg.sender, to: treasury, amount: feeAmount}));
        }

        _transferAmountFrom(_token, TransferData({from: msg.sender, to: address(_strategy), amount: amountAfterFee}));
        _strategy.increasePoolAmount(amountAfterFee);

        emit PoolFunded(_poolId, amountAfterFee, feeAmount);
    }

    /// @notice Checks if the strategy is cloneable
    /// @param _strategy The address of the strategy
    /// @return bool
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
    /// @param _percentFee The new fee
    function _updatePercentFee(uint256 _percentFee) internal {
        if (_percentFee > 1e18) {
            revert INVALID_FEE();
        }
        percentFee = _percentFee;

        emit PercentFeeUpdated(percentFee);
    }

    /// @notice Updates the base fee
    /// @param _baseFee The new base fee
    function _updateBaseFee(uint256 _baseFee) internal {
        baseFee = _baseFee;
        emit BaseFeeUpdated(baseFee);
    }

    // =========================
    // ==== View Functions =====
    // =========================

    /// @notice Getter for the fee denominator
    /// @return FEE_DENOMINATOR The fee denominator (1e18) which represents 100%
    function getFeeDenominator() public pure returns (uint256 FEE_DENOMINATOR) {
        return 1e18;
    }

    /// @notice Checks if the address is a pool admin
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool Returns true if the address is a pool admin
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolAdmin(_poolId, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @param _poolId The pool id
    /// @param _address The address to check
    /// @return bool Returns true if the address is a pool manager
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolManager(_poolId, _address);
    }

    /// @notice Return the strategy for a pool
    /// @param _poolId The pool id
    /// @return address The address of the strategy
    function getStrategy(uint256 _poolId) external view returns (address) {
        return address(pools[_poolId].strategy);
    }

    /// @notice Getter for fee percentage
    /// @return uint256 The fee percentage in 1e18
    function getPercentFee() external view returns (uint256) {
        return percentFee;
    }

    /// @notice Getter for base fee
    /// @return uint256 The base fee
    function getBaseFee() external view returns (uint256) {
        return baseFee;
    }

    /// @notice Getter for treasury address
    /// @return address The treasury address
    function getTreasury() external view returns (address payable) {
        return treasury;
    }

    /// @notice Getter for registry
    /// @return IRegistry The registry address
    function getRegistry() external view returns (IRegistry) {
        return registry;
    }

    /// @notice Getter for if strategy is cloneable
    /// @param _strategy The address of the strategy
    /// @return bool Returns true if the strategy is cloneable
    function isCloneableStrategy(address _strategy) external view returns (bool) {
        return _isCloneableStrategy(_strategy);
    }

    /// @notice Getter for the 'Pool'
    /// @param _poolId The pool id
    /// @return Pool The 'Pool' struct
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }
}
