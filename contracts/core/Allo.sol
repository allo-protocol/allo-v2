// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Imports
import {Ownable} from "solady/auth/Ownable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ClonesUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
// Internal Imports
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Native} from "contracts/core/libraries/Native.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {IBaseStrategy} from "strategies/IBaseStrategy.sol";

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
/// @notice This contract is used to create & manage _pools as well as manage the protocol.
/// @dev The contract must be initialized with the 'initialize()' function.
contract Allo is IAllo, Native, Initializable, Ownable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, Errors {
    using Transfer for address;

    // ==========================
    // === Storage Variables ====
    // ==========================

    /// @notice Percentage that is used to calculate the fee Allo takes from each pool when funded
    ///         and is deducted when a pool is funded. So if you want to fund a round with 1000 DAI and the fee
    ///         percentage is 1e17 (10%), then 100 DAI will be deducted from the 1000 DAI and the pool will be
    ///         funded with 900 DAI. The fee is then sent to the _treasury address.
    /// @dev How the percentage is represented in our contracts: 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 internal _percentFee;

    /// @notice Fee Allo charges for all _pools on creation
    /// @dev This is different from the '_percentFee' in that this is a flat fee and not a percentage. So if you want to create a pool
    ///      with a base fee of 100 DAI, then you would pass 100 DAI to the 'createPool()' function and the pool would be created
    ///      with 100 DAI less than the amount you passed to the function. The base fee is sent to the _treasury address.
    uint256 internal _baseFee;

    /// @notice Incremental index to track the _pools created
    uint256 internal _poolIndex;

    /// @notice Allo _treasury
    address payable internal _treasury;

    /// @notice Registry contract
    IRegistry internal _registry;

    /// @notice Maps the `_msgSender` to a `nonce` to prevent duplicates
    /// @dev '_msgSender' -> 'nonce' for cloning strategies
    mapping(address => uint256) internal _nonces;

    /// @notice Maps the pool ID to the pool details
    /// @dev 'Pool.id' -> 'Pool'
    mapping(uint256 => Pool) internal _pools;

    /// @custom:oz-upgrades-renamed-from cloneableStrategies
    mapping(address => bool) internal _unusedSlot;

    /// @notice The trusted forwarder contract address
    /// @dev Based on ERC2771ContextUpgradeable OZ contracts
    address internal _trustedForwarder;

    // ====================================
    // =========== Initializer =============
    // ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> a higher version should be passed to reinitializer
    /// @param _owner The owner of allo
    /// @param __registry The address of the _registry
    /// @param __treasury The address of the _treasury
    /// @param __percentFee The percentage fee
    /// @param __baseFee The base fee
    /// @param __trustedForwarder The address of the trusted forwarder
    function initialize(
        address _owner,
        address __registry,
        address payable __treasury,
        uint256 __percentFee,
        uint256 __baseFee,
        address __trustedForwarder
    ) external reinitializer(2) {
        // Initialize the owner using Solady ownable library
        _initializeOwner(_owner);

        // Set the address of the _registry
        _updateRegistry(__registry);

        // Set the address of the _treasury
        _updateTreasury(__treasury);

        // Set the fee percentage
        _updatePercentFee(__percentFee);

        // Set the base fee
        _updateBaseFee(__baseFee);

        // Set the trusted forwarder
        _updateTrustedForwarder(__trustedForwarder);
    }

    // ====================================
    // =========== Modifier ===============
    // ====================================

    // Both modifiers below are using OpenZeppelin's AccessControl.sol with custom roles under the hood

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool manager
    /// @param _poolId The pool id
    modifier onlyPoolManager(uint256 _poolId) {
        _checkOnlyPoolManager(_poolId, _msgSender());
        _;
    }

    /// @notice Reverts UNAUTHORIZED() if the caller is not a pool admin
    /// @param _poolId The pool id
    modifier onlyPoolAdmin(uint256 _poolId) {
        _checkOnlyPoolAdmin(_poolId, _msgSender());
        _;
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Creates a new pool (with a custom strategy)
    /// @dev '_msgSender' must be a member or owner of a profile to create a pool with or without a custom strategy, The encoded data
    ///      will be specific to a given strategy requirements, reference the strategy implementation of 'initialize()'. The strategy
    ///      address passed must not be the zero address. '_msgSender' must be a member or owner of the profile id passed as '_profileId'.
    /// @param _profileId The 'profileId' of the _registry profile, used to check if '_msgSender' is a member or owner of the profile
    /// @param _strategy The address of the deployed custom strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token you want to use in your pool
    /// @param _amount The amount of the token you want to deposit into the pool on initialization
    /// @param _metadata The 'Metadata' of the pool, this uses our 'Meatdata.sol' struct (consistent throughout the protocol)
    /// @param _managers The managers of the pool, and can be added/removed later by the pool admin
    /// @return _poolId The ID of the pool
    function createPoolWithCustomStrategy(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable nonReentrant returns (uint256 _poolId) {
        // Revert if the strategy address passed is the zero address with 'ZERO_ADDRESS()'
        if (_strategy == address(0)) revert ZERO_ADDRESS();

        // Call the internal '_createPool()' function and return the pool ID
        return _createPool(
            _msgSender(),
            msg.value,
            _profileId,
            IBaseStrategy(_strategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    /// @notice Creates a new pool (by cloning a deployed strategies).
    /// @dev '_msgSender' must be owner or member of the profile id passed as '_profileId'. The strategy address passed
    ///      must not be the zero address.
    /// @param _profileId The ID of the _registry profile, used to check if '_msgSender' is a member or owner of the profile
    /// @param _strategy The address of the strategy contract the pool will use.
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
    /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
    /// @custom:initstrategydata The encoded data will be specific to a given strategy requirements,
    ///    reference the strategy implementation of 'initialize()'
    /// @return _poolId The ID of the pool
    function createPool(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable nonReentrant returns (uint256 _poolId) {
        // Revert if the strategy address passed is the zero address with 'ZERO_ADDRESS()'
        if (_strategy == address(0)) revert ZERO_ADDRESS();

        address _creator = _msgSender();

        // Clone the strategy contract
        bytes32 _salt = keccak256(abi.encodePacked(_creator, _nonces[_creator]++));
        address _clone = ClonesUpgradeable.cloneDeterministic(_strategy, _salt);

        // Returns the created pool ID
        return _createPool(
            _creator,
            msg.value,
            _profileId,
            IBaseStrategy(_clone),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );
    }

    /// @notice Update pool metadata
    /// @dev '_msgSender' must be a pool manager. Emits 'PoolMetadataUpdated()' event.
    /// @param _poolId ID of the pool
    /// @param _metadata The new metadata of the pool
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external onlyPoolManager(_poolId) {
        Pool storage _pool = _pools[_poolId];
        _pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    /// @notice Updates the _registry address.
    /// @dev Use this to update the _registry address. 'msg.sender' must be Allo owner.
    /// @param __registry The new _registry address
    function updateRegistry(address __registry) external onlyOwner {
        _updateRegistry(__registry);
    }

    /// @notice Updates the _treasury address.
    /// @dev Use this to update the _treasury address. 'msg.sender' must be Allo owner.
    /// @param __treasury The new _treasury address
    function updateTreasury(address payable __treasury) external onlyOwner {
        _updateTreasury(__treasury);
    }

    /// @notice Updates the fee percentage.
    /// @dev Use this to update the fee percentage. 'msg.sender' must be Allo owner.
    /// @param __percentFee The new fee
    function updatePercentFee(uint256 __percentFee) external onlyOwner {
        _updatePercentFee(__percentFee);
    }

    /// @notice Updates the base fee.
    /// @dev Use this to update the base fee. 'msg.sender' must be Allo owner.
    /// @param __baseFee The new base fee
    function updateBaseFee(uint256 __baseFee) external onlyOwner {
        _updateBaseFee(__baseFee);
    }

    /// @notice Updates the trusted forwarder address.
    /// @dev Use this to update the trusted forwarder address.
    /// @param __trustedForwarder The new trusted forwarder address
    function updateTrustedForwarder(address __trustedForwarder) external onlyOwner {
        _updateTrustedForwarder(__trustedForwarder);
    }

    /// @notice Add multiple pool managers
    /// @dev Emits 'RoleGranted()' event. '_msgSender' must be a pool admin.
    /// @param _poolId ID of the pool
    /// @param _managers The addresses to add
    function addPoolManagers(uint256 _poolId, address[] calldata _managers) public onlyPoolAdmin(_poolId) {
        for (uint256 i; i < _managers.length; ++i) {
            _addPoolManager(_poolId, _managers[i]);
        }
    }

    /// @notice Remove multiple pool managers
    /// @dev Emits 'RoleRevoked()' event. '_msgSender' must be a pool admin.
    /// @param _poolId ID of the pool
    /// @param _managers The addresses to remove
    function removePoolManagers(uint256 _poolId, address[] calldata _managers) public onlyPoolAdmin(_poolId) {
        for (uint256 i; i < _managers.length; ++i) {
            _revokeRole(_pools[_poolId].managerRole, _managers[i]);
        }
    }

    /// @notice Add multiple pool managers to multiple _pools
    /// @param _poolIds IDs of the _pools
    /// @param _managers The addresses to add
    function addPoolManagersInMultiplePools(uint256[] calldata _poolIds, address[] calldata _managers) external {
        for (uint256 i; i < _poolIds.length; ++i) {
            addPoolManagers(_poolIds[i], _managers);
        }
    }

    /// @notice Remove multiple pool managers from multiple _pools
    /// @param _poolIds IDs of the _pools
    /// @param _managers The addresses to remove
    function removePoolManagersInMultiplePools(uint256[] calldata _poolIds, address[] calldata _managers) external {
        for (uint256 i; i < _poolIds.length; ++i) {
            removePoolManagers(_poolIds[i], _managers);
        }
    }

    /// @notice Transfer the funds recovered  to the recipient
    /// @dev 'msg.sender' must be Allo owner
    /// @param _token The token to transfer
    /// @param _recipient The recipient
    function recoverFunds(address _token, address _recipient) external onlyOwner {
        // Get the amount of the token to transfer, which is always the entire balance of the contract address
        uint256 _amount = _token == NATIVE ? address(this).balance : IERC20Upgradeable(_token).balanceOf(address(this));

        // Transfer the amount to the recipient (pool owner)
        _token.transferAmount(_recipient, _amount);
    }

    // ====================================
    // ======= Strategy Functions =========
    // ====================================

    /// @notice Passes _data through to the strategy for that pool.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of registerRecipient().
    /// @param _poolId ID of the pool
    /// @param _recipientAddresses Addresses of the recipients
    /// @param _data Encoded data unique to a strategy that registerRecipient() requires
    /// @return recipientIds The recipient IDs that have been registered
    function registerRecipient(uint256 _poolId, address[] memory _recipientAddresses, bytes memory _data)
        external
        payable
        nonReentrant
        returns (address[] memory)
    {
        // Return the recipientId (address) from the strategy
        return _pools[_poolId].strategy.register{value: msg.value}(_recipientAddresses, _data, _msgSender());
    }

    /// @notice Register multiple recipients to multiple _pools.
    /// @dev Returns the 'recipientIds' from the strategy that have been registered from calling this function.
    ///      Encoded data unique to a strategy that registerRecipient() requires. Encoded '_data' length must match
    ///      '_poolIds' length or this will revert with ARRAY_MISMATCH(). Other requirements will be determined by the strategy.
    /// @param _poolIds ID's of the _pools
    /// @param _recipientAddresses An array of recipients addresses arrays
    /// @param _data An array of encoded data unique to a strategy that registerRecipient() requires.
    /// @return _recipientIds The recipient IDs that have been registered
    function batchRegisterRecipient(
        uint256[] memory _poolIds,
        address[][] memory _recipientAddresses,
        bytes[] memory _data
    ) external nonReentrant returns (address[][] memory _recipientIds) {
        uint256 _poolIdLength = _poolIds.length;
        _recipientIds = new address[][](_poolIdLength);

        if (_poolIdLength != _data.length) revert ARRAY_MISMATCH();
        if (_poolIdLength != _recipientAddresses.length) revert ARRAY_MISMATCH();

        // Loop through the '_poolIds' & '_data' and call the 'strategy.register()' function
        for (uint256 i; i < _poolIdLength; ++i) {
            _recipientIds[i] = _pools[_poolIds[i]].strategy.register(_recipientAddresses[i], _data[i], _msgSender());
        }
    }

    /// @notice Fund a pool.
    /// @dev Anyone can fund a pool and call this function.
    /// @param _poolId ID of the pool
    /// @param _amount The amount to be deposited into the pool
    function fundPool(uint256 _poolId, uint256 _amount) external payable nonReentrant {
        // if amount is 0, revert with 'INVALID()' error
        if (_amount == 0) revert INVALID();

        Pool memory _pool = _pools[_poolId];
        if (_pool.token == NATIVE && _amount != msg.value) revert ETH_MISMATCH();

        // Call the internal fundPool() function
        _fundPool(_amount, _msgSender(), _poolId, _pool.strategy);
    }

    /// @notice Allocate to a recipient or multiple recipients.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of allocate().
    /// @param _poolId ID of the pool
    /// @param _recipients Addresses of the recipients
    /// @param _amounts Amounts to allocate to each recipient
    /// @param _data Encoded data unique to the strategy for that pool
    function allocate(uint256 _poolId, address[] memory _recipients, uint256[] memory _amounts, bytes memory _data)
        external
        payable
        nonReentrant
    {
        _allocate(_poolId, _recipients, _amounts, _data, msg.value, _msgSender());
    }

    /// @notice Allocate to multiple _pools
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of allocate().
    /// @param _poolIds IDs of the _pools
    /// @param _recipients Addresses of the recipients
    /// @param _amounts Amounts to allocate to each recipient
    /// @param _values amounts of native tokens to allocate for each pool
    /// @param _datas encoded data unique to the strategy for that pool
    function batchAllocate(
        uint256[] calldata _poolIds,
        address[][] calldata _recipients,
        uint256[][] calldata _amounts,
        uint256[] calldata _values,
        bytes[] memory _datas
    ) external payable nonReentrant {
        uint256 _numPools = _poolIds.length;

        // Reverts if the length of _poolIds does not match the length of _datas with 'ARRAY_MISMATCH()' error
        if (_numPools != _datas.length) revert ARRAY_MISMATCH();
        // Reverts if the length of _poolIds does not match the length of _values with 'ARRAY_MISMATCH()' error
        if (_numPools != _values.length) revert ARRAY_MISMATCH();
        // Reverts if the length of _poolIds does not match the length of _recipients with 'ARRAY_MISMATCH()' error
        if (_numPools != _recipients.length) revert ARRAY_MISMATCH();
        // Reverts if the length of _poolIds does not match the length of _amounts with 'ARRAY_MISMATCH()' error
        if (_numPools != _amounts.length) revert ARRAY_MISMATCH();

        // Loop through the _poolIds & _datas and call the internal _allocate() function
        uint256 _totalValue;
        address _sender = _msgSender();
        for (uint256 i; i < _numPools; ++i) {
            _allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], _sender);
            _totalValue += _values[i];
        }
        // Reverts if the sum of all the allocated values is different than 'msg.value' with 'ETH_MISMATCH()' error
        if (_totalValue != msg.value) revert ETH_MISMATCH();
    }

    /// @notice Distribute to a recipient or multiple recipients.
    /// @dev The encoded data will be specific to a given strategy requirements, reference the strategy
    ///      implementation of 'strategy.distribute()'.
    /// @param _poolId ID of the pool
    /// @param _recipientIds Ids of the recipients of the distribution
    /// @param _data Encoded data unique to the strategy
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external nonReentrant {
        _pools[_poolId].strategy.distribute(_recipientIds, _data, _msgSender());
    }

    /// @notice Revoke the admin role of an account and transfer it to another account
    /// @dev '_msgSender' must be a pool admin.
    /// @param _poolId ID of the pool
    /// @param _newAdmin The address of the new admin
    function changeAdmin(uint256 _poolId, address _newAdmin) external onlyPoolAdmin(_poolId) {
        if (_newAdmin == address(0)) revert ZERO_ADDRESS();

        _revokeRole(_pools[_poolId].adminRole, _msgSender());
        _grantRole(_pools[_poolId].adminRole, _newAdmin);
    }

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================

    /// @notice Internal function to check is caller is pool manager
    /// @param _poolId The pool id
    /// @param _address The address to check
    function _checkOnlyPoolManager(uint256 _poolId, address _address) internal view virtual {
        if (!_isPoolManager(_poolId, _address)) revert UNAUTHORIZED();
    }

    /// @notice Internal function to check is caller is pool admin
    /// @param _poolId The pool id
    /// @param _address The address to check
    function _checkOnlyPoolAdmin(uint256 _poolId, address _address) internal view virtual {
        if (!_isPoolAdmin(_poolId, _address)) revert UNAUTHORIZED();
    }

    /// @notice Creates a new pool.
    /// @dev This is an internal function that is called by the 'createPool()' & 'createPoolWithCustomStrategy()' functions
    ///      It is used to create a new pool and is called by both functions. The '_msgSender' must be a member or owner of
    ///      a profile to create a pool.
    /// @param _creator The address that is creating the pool
    /// @param _msgValue The value paid by the sender of this transaciton
    /// @param _profileId The ID of the profile of for pool creator in the _registry
    /// @param _strategy The address of strategy
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token that the pool is denominated in
    /// @param _amount The amount of the token to be deposited into the pool
    /// @param _metadata The 'Metadata' of the pool
    /// @param _managers The managers of the pool
    /// @return _poolId The ID of the pool
    function _createPool(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) internal virtual returns (uint256 _poolId) {
        if (!_registry.isOwnerOrMemberOfProfile(_profileId, _creator)) revert UNAUTHORIZED();

        _poolId = ++_poolIndex;

        // Generate the manager & admin roles for the pool (this is the way we do this throughout the protocol for consistency)
        bytes32 _poolManagerRole = bytes32(_poolId);
        bytes32 _poolAdminRole = keccak256(abi.encodePacked(_poolId, "admin"));

        // Create the Pool instance
        Pool memory pool = Pool({
            profileId: _profileId,
            strategy: _strategy,
            metadata: _metadata,
            token: _token,
            managerRole: _poolManagerRole,
            adminRole: _poolAdminRole
        });

        // Add the pool to the mapping of created _pools
        _pools[_poolId] = pool;

        // Grant admin roles to the pool creator
        _grantRole(_poolAdminRole, _creator);

        // Set admin role for POOL_MANAGER_ROLE
        _setRoleAdmin(_poolManagerRole, _poolAdminRole);

        // initialize strategies
        // Initialization is expected to revert when invoked more than once with 'ALREADY_INITIALIZED()' error
        _strategy.initialize(_poolId, _initStrategyData);

        if (_strategy.getPoolId() != _poolId || address(_strategy.getAllo()) != address(this)) revert MISMATCH();

        // grant pool managers roles
        uint256 _managersLength = _managers.length;
        for (uint256 i; i < _managersLength; ++i) {
            _addPoolManager(_poolId, _managers[i]);
        }

        if (_baseFee > 0) {
            // To prevent paying the _baseFee from the Allo contract's balance
            // If _token is NATIVE, then _baseFee + _amount should be equal to _msgValue.
            // If _token is not NATIVE, then _baseFee should be equal to _msgValue.
            if (_token == NATIVE && (_baseFee + _amount != _msgValue)) revert ETH_MISMATCH();
            if (_token != NATIVE && _baseFee != _msgValue) revert ETH_MISMATCH();

            address(_treasury).transferAmountNative(_baseFee);

            emit BaseFeePaid(_poolId, _baseFee);
        }

        if (_amount > 0) {
            _fundPool(_amount, _creator, _poolId, _strategy);
        }

        emit PoolCreated(_poolId, _profileId, _strategy, _token, _amount, _metadata);
    }

    /// @notice Allocate to recipient(s).
    /// @dev Passes '_data' & '_allocator' through to the strategy for that pool.
    ///      This is an internal function that is called by the 'allocate()' & 'batchAllocate()' functions.
    /// @param _poolId ID of the pool
    /// @param _recipients Addresses of the recipients
    /// @param _amounts Amount of tokens to allocate to strategy
    /// @param _data Encoded data unique to the strategy for that pool
    /// @param _value The native token value sent
    /// @param _allocator Address that is invoking the allocation
    function _allocate(
        uint256 _poolId,
        address[] memory _recipients,
        uint256[] memory _amounts,
        bytes memory _data,
        uint256 _value,
        address _allocator
    ) internal virtual {
        _pools[_poolId].strategy.allocate{value: _value}(_recipients, _amounts, _data, _allocator);
    }

    /// @notice Fund a pool.
    /// @dev Deducts the fee and transfers the amount to the distribution strategy.
    ///      Emits a 'PoolFunded' event.
    /// @param _amount The amount to transfer
    /// @param _funder The address providing the funding
    /// @param _poolId The 'poolId' for the pool you are funding
    /// @param _strategy The address of the strategy
    function _fundPool(uint256 _amount, address _funder, uint256 _poolId, IBaseStrategy _strategy) internal virtual {
        uint256 _feeAmount = (_amount * _percentFee) / getFeeDenominator(); // Can be zero if _percentFee is zero
        uint256 _amountAfterFee = _amount - _feeAmount;

        address _token = _pools[_poolId].token;

        if (_token == NATIVE && msg.value < _amount) revert ETH_MISMATCH();

        if (_feeAmount > 0) {
            uint256 _balanceBeforeFee = _token.getBalance(_treasury);
            _token.transferAmountFrom(_funder, _treasury, _feeAmount);
            uint256 _balanceAfterFee = _token.getBalance(_treasury);
            // Track actual fee paid to account for fee on ERC20 token transfers
            _feeAmount = _balanceAfterFee - _balanceBeforeFee;
        }

        uint256 _balanceBeforeFundingPool = _token.getBalance(address(_strategy));
        _token.transferAmountFrom(_funder, address(_strategy), _amountAfterFee);
        uint256 _balanceAfterFundingPool = _token.getBalance(address(_strategy));
        // Track actual fee paid to account for fee on ERC20 token transfers
        _amountAfterFee = _balanceAfterFundingPool - _balanceBeforeFundingPool;

        _strategy.increasePoolAmount(_amountAfterFee);

        emit PoolFunded(_poolId, _amountAfterFee, _feeAmount);
    }

    /// @notice Checks if the address is a pool admin
    /// @dev Internal function used to determine if an address is a pool admin
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return This will return 'true' if the address is a pool admin, otherwise 'false'
    function _isPoolAdmin(uint256 _poolId, address _address) internal view virtual returns (bool) {
        return hasRole(_pools[_poolId].adminRole, _address);
    }

    /// @notice Checks if the address is a pool manager
    /// @dev Internal function used to determine if an address is a pool manager
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return This will return 'true' if the address is a pool manager, otherwise 'false'
    function _isPoolManager(uint256 _poolId, address _address) internal view virtual returns (bool) {
        return hasRole(_pools[_poolId].managerRole, _address) || _isPoolAdmin(_poolId, _address);
    }

    /// @notice Updates the _registry address
    /// @dev Internal function used to update the _registry address.
    ///      Emits a RegistryUpdated event.
    /// @param __registry The new _registry address
    function _updateRegistry(address __registry) internal virtual {
        if (__registry == address(0)) revert ZERO_ADDRESS();

        _registry = IRegistry(__registry);
        emit RegistryUpdated(__registry);
    }

    /// @notice Updates the _treasury address
    /// @dev Internal function used to update the _treasury address.
    ///      Emits a TreasuryUpdated event.
    /// @param __treasury The new _treasury address
    function _updateTreasury(address payable __treasury) internal virtual {
        if (__treasury == address(0)) revert ZERO_ADDRESS();

        _treasury = __treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice Updates the fee percentage
    /// @dev Internal function used to update the percentage fee.
    ///      Emits a PercentFeeUpdated event.
    /// @param __percentFee The new fee
    function _updatePercentFee(uint256 __percentFee) internal virtual {
        if (__percentFee > 1e18) revert INVALID();

        _percentFee = __percentFee;

        emit PercentFeeUpdated(_percentFee);
    }

    /// @notice Updates the base fee
    /// @dev Internal function used to update the base fee.
    ///      Emits a BaseFeeUpdated event.
    /// @param __baseFee The new base fee
    function _updateBaseFee(uint256 __baseFee) internal virtual {
        _baseFee = __baseFee;

        emit BaseFeeUpdated(_baseFee);
    }

    /// @notice Updates the trusted forwarder address
    /// @dev Internal function used to update the trusted forwarder address.
    ///      Emits a TrustedForwarderUpdated event.
    /// @param __trustedForwarder The new trusted forwarder address
    function _updateTrustedForwarder(address __trustedForwarder) internal virtual {
        _trustedForwarder = __trustedForwarder;

        emit TrustedForwarderUpdated(__trustedForwarder);
    }

    /// @notice Adds a pool manager
    /// @dev Internal function used to add a pool manager.
    /// @param _poolId The ID of the pool
    /// @param _manager The address to add
    function _addPoolManager(uint256 _poolId, address _manager) internal virtual {
        // Reverts if the address is the zero address with 'ZERO_ADDRESS()'
        if (_manager == address(0)) revert ZERO_ADDRESS();

        // Grants the pool manager role to the '_manager' address
        _grantRole(_pools[_poolId].managerRole, _manager);
    }

    /// @dev Logic copied from ERC2771ContextUpgradeable OZ contracts
    /// @return the sender of the call
    function _msgSender() internal view virtual override returns (address) {
        uint256 _calldataLength = msg.data.length;
        if (isTrustedForwarder(msg.sender) && _calldataLength >= 20) {
            return address(bytes20(msg.data[_calldataLength - 20:]));
        } else {
            return super._msgSender();
        }
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
        return address(_pools[_poolId].strategy);
    }

    /// @notice Getter for fee percentage.
    /// @return The fee percentage (1e18 = 100%)
    function getPercentFee() external view returns (uint256) {
        return _percentFee;
    }

    /// @notice Getter for base fee.
    /// @return The base fee
    function getBaseFee() external view returns (uint256) {
        return _baseFee;
    }

    /// @notice Getter for _treasury address.
    /// @return The _treasury address
    function getTreasury() external view returns (address payable) {
        return _treasury;
    }

    /// @notice Getter for _registry.
    /// @return The _registry address
    function getRegistry() external view returns (IRegistry) {
        return _registry;
    }

    /// @notice Getter for the 'Pool'.
    /// @param _poolId The ID of the pool
    /// @return The 'Pool' struct
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return _pools[_poolId];
    }

    /// @dev Logic copied from ERC2771ContextUpgradeable OZ contracts
    /// @param _forwarder address to check if it is trusted
    /// @return true if it is trusted, false otherwise
    function isTrustedForwarder(address _forwarder) public view returns (bool) {
        return _forwarder == _trustedForwarder;
    }
}
