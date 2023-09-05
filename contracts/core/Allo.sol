// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import "solady/src/auth/Ownable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
// Interfaces
import "./interfaces/IAllo.sol";

// Internal Libraries
import {Clone} from "./libraries/Clone.sol";
import {Errors} from "./libraries/Errors.sol";
import "./libraries/Native.sol";
import {Transfer} from "./libraries/Transfer.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Allo
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice This contract is used to create & manage pools as well as manage the protocol.
/// @dev The contract must be initialized with the 'initialize()' function.
contract Allo is IAllo, Native, Transfer, Initializable, Ownable, AccessControl, ReentrancyGuardUpgradeable, Errors {
    // ==========================
    // === Storage Variables ====
    // ==========================

    /// @notice Percentage that is used to calculate the fee Allo takes from each pool when funded
    ///         and is deducted when a pool is funded. So if you want to fund a round with 1000 DAI and the fee
    ///         percentage is 1e17 (10%), then 100 DAI will be deducted from the 1000 DAI and the pool will be
    ///         funded with 900 DAI. The fee is then sent to the treasury address.
    /// @dev How the percentage is represented in our contracts: 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 private percentFee;

    /// @notice Fee Allo charges for all pools on creation
    /// @dev This is different from the 'percentFee' in that this is a flat fee and not a percentage. So if you want to create a pool
    ///      with a base fee of 100 DAI, then you would pass 100 DAI to the 'createPool()' function and the pool would be created
    ///      with 100 DAI less than the amount you passed to the function. The base fee is sent to the treasury address.
    uint256 internal baseFee;

    /// @notice Incremental index to track the pools created
    uint256 private _poolIndex;

    /// @notice Allo treasury
    address payable private treasury;

    /// @notice Registry contract
    IRegistry private registry;

    /// @notice Maps the `msg.sender` to a `nonce` to prevent duplicates
    /// @dev 'msg.sender' -> 'nonce' for cloning strategies
    mapping(address => uint256) private _nonces;

    /// @notice Maps the pool ID to the pool details
    /// @dev 'Pool.id' -> 'Pool'
    mapping(uint256 => Pool) private pools;

    /// @notice Returns a bool for whether a strategy is cloneable or not using the strategy address as the key
    /// @dev Strategy.address -> bool
    mapping(address => bool) private cloneableStrategies;

    // ====================================
    // =========== Initializer =============
    // ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> a higher version should be passed to reinitializer
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

    // Both modifiers below are using OpenZeppelin's AccessControl.sol with custom roles under the hood

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool manager
    /// @param _poolId The pool id
    modifier onlyPoolManager(uint256 _poolId) {
        _checkOnlyPoolManager(_poolId);
        _;
    }

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool admin
    /// @param _poolId The pool id
    modifier onlyPoolAdmin(uint256 _poolId) {
        _checkOnlyPoolAdmin(_poolId);
        _;
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Creates a new pool (with a custom strategy)
    /// @dev 'msg.sender' must be a member or owner of a profile to create a pool with or without a custom strategy, The encoded data
    ///      will be specific to a given strategy requirements, reference the strategy implementation of 'initialize()'. The strategy
    ///      address passed must not be a cloneable strategy. The strategy address passed must not be the zero address. 'msg.sender' must
    ///      be a member or owner of the profile id passed as '_profileId'.
    /// @param _profileId The 'profileId' of the registry profile, used to check if 'msg.sender' is a member or owner of the profile
    /// @param _strategy The address of the deployed custom strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token you want to use in your pool
    /// @param _amount The amount of the token you want to deposit into the pool on initialization
    /// @param _metadata The 'Metadata' of the pool, this uses our 'Meatdata.sol' struct (consistent throughout the protocol)
    /// @param _managers The managers of the pool, and can be added/removed later by the pool admin
    /// @return poolId The ID of the pool
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
        if (_strategy == address(0)) revert ZERO_ADDRESS();

        // Revert if we already have this strategy in our cloneable mapping with 'IS_APPROVED_STRATEGY()' (only non-cloneable strategies can be used)
        if (_isCloneableStrategy(_strategy)) revert IS_APPROVED_STRATEGY();

        // Call the internal '_createPool()' function and return the pool ID
        return _createPool(_profileId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
    }

    /// @notice Creates a new pool (by cloning a cloneable strategies).
    /// @dev 'msg.sender' must be owner or member of the profile id passed as '_profileId'.
    /// @param _profileId The ID of the registry profile, used to check if 'msg.sender' is a member or owner of the profile
    /// @param _strategy The address of the strategy contract the pool will use.
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
    ) external payable nonReentrant returns (uint256 poolId) {
        if (!_isCloneableStrategy(_strategy)) {
            revert NOT_APPROVED_STRATEGY();
        }

        // Returns the created pool ID
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
    /// @dev 'msg.sender' must be a pool manager. Emits 'PoolMetadataUpdated()' event.
    /// @param _poolId ID of the pool
    /// @param _metadata The new metadata of the pool
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external onlyPoolManager(_poolId) {
        Pool storage pool = pools[_poolId];
        pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    /// @notice Updates the registry address.
    /// @dev Use this to update the registry address. 'msg.sender' must be Allo owner.
    /// @param _registry The new registry address
    function updateRegistry(address _registry) external onlyOwner {
        _updateRegistry(_registry);
    }

    /// @notice Updates the treasury address.
    /// @dev Use this to update the treasury address. 'msg.sender' must be Allo owner.
    /// @param _treasury The new treasury address
    function updateTreasury(address payable _treasury) external onlyOwner {
        _updateTreasury(_treasury);
    }

    /// @notice Updates the fee percentage.
    /// @dev Use this to update the fee percentage. 'msg.sender' must be Allo owner.
    /// @param _percentFee The new fee
    function updatePercentFee(uint256 _percentFee) external onlyOwner {
        _updatePercentFee(_percentFee);
    }

    /// @notice Updates the base fee.
    /// @dev Use this to update the base fee. 'msg.sender' must be Allo owner.
    /// @param _baseFee The new base fee
    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        _updateBaseFee(_baseFee);
    }

    /// @notice Add a strategy to the allowlist.
    /// @dev Emits the 'StrategyApproved()' event. 'msg.sender' must be Allo owner.
    /// @param _strategy The address of the strategy
    function addToCloneableStrategies(address _strategy) external onlyOwner {
        if (_strategy == address(0)) revert ZERO_ADDRESS();

        cloneableStrategies[_strategy] = true;
        emit StrategyApproved(_strategy);
    }

    /// @notice Remove a strategy from the allowlist
    /// @dev Emits 'StrategyRemoved()' event. 'msg.sender must be Allo owner.
    /// @param _strategy The address of the strategy
    function removeFromCloneableStrategies(address _strategy) external onlyOwner {
        // Set the strategy to false in the cloneableStrategies mapping
        cloneableStrategies[_strategy] = false;

        // Emit the StrategyRemoved event
        emit StrategyRemoved(_strategy);
    }

    /// @notice Add a pool manager
    /// @dev Emits 'RoleGranted()' event. 'msg.sender' must be a pool admin.
    /// @param _poolId ID of the pool
    /// @param _manager The address to add
    function addPoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        // Reverts if the address is the zero address with 'ZERO_ADDRESS()'
        if (_manager == address(0)) revert ZERO_ADDRESS();

        // Grants the pool manager role to the '_manager' address
        _grantRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Remove a pool manager
    /// @dev Emits 'RoleRevoked()' event. 'msg.sender' must be a pool admin.
    /// @param _poolId ID of the pool
    /// @param _manager The address to remove
    function removePoolManager(uint256 _poolId, address _manager) external onlyPoolAdmin(_poolId) {
        _revokeRole(pools[_poolId].managerRole, _manager);
    }

    /// @notice Transfer the funds recovered  to the recipient
    /// @dev 'msg.sender' must be Allo owner
    /// @param _token The token to transfer
    /// @param _recipient The recipient
    function recoverFunds(address _token, address _recipient) external onlyOwner {
        // Get the amount of the token to transfer, which is always the entire balance of the contract address
        uint256 amount = _token == NATIVE ? address(this).balance : IERC20Upgradeable(_token).balanceOf(address(this));

        // Transfer the amount to the recipient (pool owner)
        _transferAmount(_token, _recipient, amount);
    }

    // ====================================
    // ======= Strategy Functions =========
    // ====================================

    /// @notice Passes _data through to the strategy for that pool.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of registerRecipient().
    /// @param _poolId ID of the pool
    /// @param _data Encoded data unique to a strategy that registerRecipient() requires
    /// @return recipientId The recipient ID that has been registered
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable nonReentrant returns (address) {
        // Return the recipientId (address) from the strategy
        return pools[_poolId].strategy.registerRecipient(_data, msg.sender);
    }

    /// @notice Register multiple recipients to multiple pools.
    /// @dev Returns the 'recipientIds' from the strategy that have been registered from calling this function.
    ///      Encoded data unique to a strategy that registerRecipient() requires. Encoded '_data' length must match
    ///      '_poolIds' length or this will revert with MISMATCH(). Other requirements will be determined by the strategy.
    /// @param _poolIds ID's of the pools
    /// @param _data An array of encoded data unique to a strategy that registerRecipient() requires.
    /// @return recipientIds The recipient IDs that have been registered
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        nonReentrant
        returns (address[] memory recipientIds)
    {
        uint256 poolIdLength = _poolIds.length;
        recipientIds = new address[](poolIdLength);

        if (poolIdLength != _data.length) revert MISMATCH();

        // Loop through the '_poolIds' & '_data' and call the 'strategy.registerRecipient()' function
        for (uint256 i; i < poolIdLength;) {
            recipientIds[i] = pools[_poolIds[i]].strategy.registerRecipient(_data[i], msg.sender);
            unchecked {
                ++i;
            }
        }

        // Return the recipientIds that have been registered
        return recipientIds;
    }

    /// @notice Fund a pool.
    /// @dev Anyone can fund a pool and call this function.
    /// @param _poolId ID of the pool
    /// @param _amount The amount to be deposited into the pool
    function fundPool(uint256 _poolId, uint256 _amount) external payable nonReentrant {
        // if amount is 0, revert with 'NOT_ENOUGH_FUNDS()' error
        if (_amount == 0) revert NOT_ENOUGH_FUNDS();

        // Call the internal fundPool() function
        _fundPool(_amount, _poolId, pools[_poolId].strategy);
    }

    /// @notice Allocate to a recipient or multiple recipients.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of allocate().
    /// @param _poolId ID of the pool
    /// @param _data Encoded data unique to the strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable nonReentrant {
        _allocate(_poolId, _data);
    }

    /// @notice Allocate to multiple pools
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of allocate(). Please note that this is not a 'payable' function, so if you
    ///      want to send funds to the strategy, you must send the funds using 'fundPool()'.
    /// @param _poolIds IDs of the pools
    /// @param _datas encoded data unique to the strategy for that pool
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external nonReentrant {
        uint256 numPools = _poolIds.length;

        // Reverts if the length of _poolIds does not match the length of _datas with 'MISMATCH()' error
        if (numPools != _datas.length) revert MISMATCH();

        // Loop through the _poolIds & _datas and call the internal _allocate() function
        for (uint256 i; i < numPools;) {
            _allocate(_poolIds[i], _datas[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Distribute to a recipient or multiple recipients.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of 'strategy.distribute()'.
    /// @param _poolId ID of the pool
    /// @param _recipientIds Ids of the recipients of the distribution
    /// @param _data Encoded data unique to the strategy
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external nonReentrant {
        pools[_poolId].strategy.distribute(_recipientIds, _data, msg.sender);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Internal function to check is caller is pool manager
    /// @param _poolId The pool id
    function _checkOnlyPoolManager(uint256 _poolId) internal view {
        if (!_isPoolManager(_poolId, msg.sender)) revert UNAUTHORIZED();
    }

    /// @notice Internal function to check is caller is pool admin
    /// @param _poolId The pool id
    function _checkOnlyPoolAdmin(uint256 _poolId) internal view {
        if (!_isPoolAdmin(_poolId, msg.sender)) revert UNAUTHORIZED();
    }

    /// @notice Creates a new pool.
    /// @dev This is an internal function that is called by the 'createPool()' & 'createPoolWithCustomStrategy()' functions
    ///      It is used to create a new pool and is called by both functions. The 'msg.sender' must be a member or owner of
    ///      a profile to create a pool.
    /// @param _profileId The ID of the profile of for pool creator in the registry
    /// @param _strategy The address of strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The 'Metadata' of the pool
    /// @param _managers The managers of the pool
    /// @return poolId The ID of the pool
    function _createPool(
        bytes32 _profileId,
        IStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal returns (uint256 poolId) {
        if (!registry.isOwnerOrMemberOfProfile(_profileId, msg.sender)) revert UNAUTHORIZED();

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
        // Initialization is expected to revert when invoked more than once with 'ALREADY_INITIALIZED()' error
        _strategy.initialize(poolId, _initStrategyData);

        if (_strategy.getPoolId() != poolId || address(_strategy.getAllo()) != address(this)) revert MISMATCH();

        // grant pool managers roles
        uint256 managersLength = _managers.length;
        for (uint256 i; i < managersLength;) {
            address manager = _managers[i];
            if (manager == address(0)) revert ZERO_ADDRESS();

            _grantRole(POOL_MANAGER_ROLE, manager);
            unchecked {
                ++i;
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

    /// @notice Allocate to recipient(s).
    /// @dev Passes '_data' & 'msg.sender' through to the strategy for that pool.
    ///      This is an internal function that is called by the 'allocate()' & 'batchAllocate()' functions.
    /// @param _poolId ID of the pool
    /// @param _data Encoded data unique to the strategy for that pool
    function _allocate(uint256 _poolId, bytes memory _data) internal {
        pools[_poolId].strategy.allocate{value: msg.value}(_data, msg.sender);
    }

    /// @notice Fund a pool.
    /// @dev Deducts the fee and transfers the amount to the distribution strategy.
    ///      Emits a 'PoolFunded' event.
    /// @param _amount The amount to transfer
    /// @param _poolId The 'poolId' for the pool you are funding
    /// @param _strategy The address of the strategy
    function _fundPool(uint256 _amount, uint256 _poolId, IStrategy _strategy) internal {
        uint256 feeAmount;
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

    /// @notice Checks if the strategy is an approved cloneable strategy.
    /// @dev Internal function used by createPoolwithCustomStrategy and createPool to
    ///      determine if a strategy is in the cloneable strategy allow list.
    /// @param _strategy The address of the strategy
    /// @return This will return 'true' if the strategy is cloneable, otherwise 'false'
    function _isCloneableStrategy(address _strategy) internal view returns (bool) {
        return cloneableStrategies[_strategy];
    }

    /// @notice Checks if the address is a pool admin
    /// @dev Internal function used to determine if an address is a pool admin
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return This will return 'true' if the address is a pool admin, otherwise 'false'
    function _isPoolAdmin(uint256 _poolId, address _address) internal view returns (bool) {
        return hasRole(pools[_poolId].adminRole, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @dev Internal function used to determine if an address is a pool manager
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return This will return 'true' if the address is a pool manager, otherwise 'false'
    function _isPoolManager(uint256 _poolId, address _address) internal view returns (bool) {
        return hasRole(pools[_poolId].managerRole, _address) || _isPoolAdmin(_poolId, _address);
    }

    /// @notice Updates the registry address
    /// @dev Internal function used to update the registry address.
    ///      Emits a RegistryUpdated event.
    /// @param _registry The new registry address
    function _updateRegistry(address _registry) internal {
        if (_registry == address(0)) revert ZERO_ADDRESS();

        registry = IRegistry(_registry);
        emit RegistryUpdated(_registry);
    }

    /// @notice Updates the treasury address
    /// @dev Internal function used to update the treasury address.
    ///      Emits a TreasuryUpdated event.
    /// @param _treasury The new treasury address
    function _updateTreasury(address payable _treasury) internal {
        if (_treasury == address(0)) revert ZERO_ADDRESS();

        treasury = _treasury;
        emit TreasuryUpdated(treasury);
    }

    /// @notice Updates the fee percentage
    /// @dev Internal function used to update the percentage fee.
    ///      Emits a PercentFeeUpdated event.
    /// @param _percentFee The new fee
    function _updatePercentFee(uint256 _percentFee) internal {
        if (_percentFee > 1e18) revert INVALID_FEE();

        percentFee = _percentFee;

        emit PercentFeeUpdated(percentFee);
    }

    /// @notice Updates the base fee
    /// @dev Internal function used to update the base fee.
    ///      Emits a BaseFeeUpdated event.
    /// @param _baseFee The new base fee
    function _updateBaseFee(uint256 _baseFee) internal {
        baseFee = _baseFee;

        emit BaseFeeUpdated(baseFee);
    }

    // =========================
    // ==== View Functions =====
    // =========================

    /// @notice Getter for the fee denominator
    /// @return FEE_DENOMINATOR The fee denominator is (1e18) which represents 100%
    function getFeeDenominator() public pure returns (uint256 FEE_DENOMINATOR) {
        return 1e18;
    }

    /// @notice Checks if the address is a pool admin.
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return 'true' if the address is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolAdmin(_poolId, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return 'true' if the address is a pool manager, otherwise 'false'
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool) {
        return _isPoolManager(_poolId, _address);
    }

    /// @notice Getter for the strategy.
    /// @param _poolId The ID of the pool
    /// @return The address of the strategy
    function getStrategy(uint256 _poolId) external view returns (address) {
        return address(pools[_poolId].strategy);
    }

    /// @notice Getter for fee percentage.
    /// @return The fee percentage (1e18 = 100%)
    function getPercentFee() external view returns (uint256) {
        return percentFee;
    }

    /// @notice Getter for base fee.
    /// @return The base fee
    function getBaseFee() external view returns (uint256) {
        return baseFee;
    }

    /// @notice Getter for treasury address.
    /// @return The treasury address
    function getTreasury() external view returns (address payable) {
        return treasury;
    }

    /// @notice Getter for registry.
    /// @return The registry address
    function getRegistry() external view returns (IRegistry) {
        return registry;
    }

    /// @notice Getter for if strategy is cloneable.
    /// @param _strategy The address of the strategy
    /// @return 'true' if the strategy is cloneable, otherwise 'false'
    function isCloneableStrategy(address _strategy) external view returns (bool) {
        return _isCloneableStrategy(_strategy);
    }

    /// @notice Getter for the 'Pool'.
    /// @param _poolId The ID of the pool
    /// @return The 'Pool' struct
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }
}
