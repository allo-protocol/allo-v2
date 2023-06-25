// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@solady/auth/Ownable.sol";

import {Metadata} from "./libraries/Metadata.sol";
import "../interfaces/IAllocationStrategy.sol";
import "../interfaces/IDistributionStrategy.sol";
import "./Registry.sol";

contract Allo is Initializable, Ownable, MulticallUpgradeable {
    error NO_ACCESS_TO_ROLE();

    error TRANSFER_FAILED();

    /// @notice Struct to hold details of an Pool
    struct Pool {
        bytes32 identityId;
        IAllocationStrategy allocationStrategy;
        IDistributionStrategy distributionStrategy;
        Metadata metadata;
        address token;
        uint256 amount;
        bool active;
    }

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Incremental Index
    uint256 private _poolIndex;

    /// @notice Nonce to create salt for clone strategy
    uint256 private _nonce;

    /// @notice Fee
    uint256 public fee; // ASK: should this be percentage ?

    /// @notice Allo Treasury
    address public treasury;

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

    // creates pool locally, transfers pool amount to distribution strategy => returns poolId
    // takes fee from user

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
        if (!registry.isMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        Pool memory pool = Pool({
            identityId: _identityId,
            allocationStrategy: IAllocationStrategy(_createClone(_allocationStrategy)),
            distributionStrategy: IDistributionStrategy(_createClone(_distributionStrategy)),
            token: _token,
            amount: _amount,
            metadata: _metadata,
            active: true
        });

        // TODO: Add fee logic

        _transferAmount(payable(address(pool.distributionStrategy)), _amount, _token);

        poolId = _poolIndex++;
        pools[poolId] = pool;

        emit PoolCreated(poolId, _identityId, _allocationStrategy, _distributionStrategy, _token, _amount, _metadata);
    }

    /// @notice passes _data through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function applyToPool(uint256 _poolId, bytes memory _data) external payable returns (uint256 applicationId) {
        IAllocationStrategy allocationStrategy = pools[_poolId].allocationStrategy;
        applicationId = allocationStrategy.applyToPool(_data, msg.sender);
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
    }

    /// @notice Fund a pool
    /// @param _poolId id of the pool
    /// @param _amount extra amount of the token to be deposited into the pool
    function fundPool(uint256 _poolId, uint256 _amount) external payable {
        // TODO: Should this be restricted to pool owner?
        // TODO: Add fee logic

        Pool storage pool = pools[_poolId];

        _transferAmount(payable(address(pool.distributionStrategy)), _amount, pool.token);
        pool.amount += _amount;

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
        pool.disributionStrategy.activatePayouts(dataFromAllocationStrategy, _dataFromPoolOwner);
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the disributionStrategy strategy for that pool
    /// @dev Only callable by the pool member
    function distribute(uint256 _poolId, bytes memory _data) external isPoolMember(_poolId) {
        pools[_poolId].disributionStrategy.distribute(_data, msg.sender);
    }

    // TODO: DO WE NEED THIS? Not every strategy needs this
    /// @notice Closes the pool
    /// @param _poolId id of the pool
    /// @dev Only callable by the pool member
    function closePool(uint256 _poolId) external isPoolMember(_poolId) {
        // pools[_poolId].allocationStrategy.close(); // ASK: Do we need this ?
        pools[_poolId].distributionStrategy.close();
        pools[_poolId].active = false;
        emit PoolClosed(_poolId);
    }

    /// @notice Updates the treasury address
    /// @param _treasury The new treasury address
    /// @dev Only callable by the owner
    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(treasury);
    }

    /// @notice Updates the fee
    /// @param _fee The new fee
    /// @dev Only callable by the owner
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeUpdated(fee);
    }

    /// @notice Create a determenstic clone of of contract
    /// @param _contract The address of the contract to clone
    function _createClone(address _contract) internal returns (address clone) {
        require(_isContract(_contract), "not a contract");
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _nonce++));
        clone = ClonesUpgradeable.cloneDeterministic(_contract, salt);
    }

    /// @notice Checks if the address is a contract
    /// @param _address The address to check
    function _isContract(address _address) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }
        return codeSize > 0;
    }

    /// @notice Transfers the amount to the address
    /// @param _to The address to transfer to
    /// @param _amount The amount to transfer
    /// @param _token The address of the token to transfer
    function _transferAmount(address payable _to, uint256 _amount, address _token) internal {
        if (_token == address(0)) {
            // Native Token
            (bool sent, bytes memory data) = _to.call{value: _amount}("");
            if (!sent) {
                revert TRANSFER_FAILED();
            }
        } else {
            // ERC20 Token
            IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        }
    }

    // ASK: Should registry be updatable
    // ASK: Should we allow multiple registries
    // ASK: Do we need closePool
    // ASK: If yes -> do we need openPool to set active = true
}
