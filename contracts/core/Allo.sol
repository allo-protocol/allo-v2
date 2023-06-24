// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Metadata} from "./libraries/Metadata.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAllocationStrategy.sol";
import "../interfaces/IDistributionStrategy.sol";
import "./Registry.sol";

contract Allo is Initializable {
    error NO_ACCESS_TO_ROLE();

    /// @notice Struct to hold details of an Pool
    struct Pool {
        bytes32 identityId;
        IAllocationStrategy allocationStrategy;
        IDistributionStrategy distributionStrategy;
        Metadata metadata;
        bool active;
    }

    /// @notice Registry of pool creators
    Registry public registry;

    /// @notice Incremental Index
    uint256 private _poolIndex;

    /// @notice Pool.id -> Pool
    mapping(uint256 => Pool) public pools;

    /// @notice Allo Treasury
    address public treasury;

    // Events
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        address allocationStrategy,
        address distributionStrategy,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadat metadata);

    event PoolClosed(uint256 indexed poolId);

    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize(address _registry) public reinitializer(1) {
        registry = Registry(_registry);
        // ASK: should there be an update function to update registry ? Ownable contract ?
        // Should this contract be upgradable
    }

    /// @notice Fetch pool and identityMetadata
    /// @param _poolId The id of the pool
    /// @dev calls out to the registry to get the identity metadata
    function getIdentityInfo(uint256 _poolId)
        external
        view
        returns (Pool memory pool, string memory identityMetadata)
    {
        pool = pools[_poolId];
        identityMetadata = registry.identities(pool.identityId).metadata;
        // ASK: why are we returning the pool
    }

    // @todo insert clonable strategy library, including validation that an existing pool has safe strategy

    // creates pool locally, transfers pool amount to distribution strategy => returns poolId
    // takes fee from user
    // validates that the owner is actually allowed to use the identity
    function createPool(
        bytes32 _identityId,
        address _allocationStrategy,
        address _distributionStrategy,
        Metadata _metadata
    ) external pure returns (uint256 poolId) {
        if (!registry.isMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        // ASK should we clone _allocationStrategy / _distributionStrategy or just use them directly?
        // bytes32 salt = keccak256(abi.encodePacked(msg.sender, nonce, "allocationStrategy"));
        // address clone = ClonesUpgradeable.cloneDeterministic(_allocationStrategy, salt);

        Pool memory pool = Pool(
            _identityId,
            IAllocationStrategy(_allocationStrategy),
            IDistributionStrategy(_distributionStrategy),
            _metadata,
            false
        );

        // ASK: Does this function also recieve funds ?
        // If so -> ETH / ERC20 ?
        // Should we also accept amount as an argument to check ?

        poolId = _poolIndex++;
        pools[poolId] = pool;

        emit PoolCreated(poolId, _identityId, _allocationStrategy, _distributionStrategy, _metadata);
    }

    /// @notice passes _data through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function applyToPool(uint256 _poolId, bytes memory _data) external payable returns (uint256 applicationId) {
        IAllocationStrategy allocationStrategy = pools[_poolId].allocationStrategy;
        applicationId = allocationStrategy.applyToRound(_data, msg.sender);
    }

    /// @notice Update pool metadata
    /// @param _poolId id of the pool
    /// @param _metadata new metadata of the pool
    /// @dev invoked only by pool owner
    function updatePoolMetadata(uint256 _poolId, bytes memory _metadata) external payable returns (bytes memory) {
        if (!registry.isMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        Pool storage pool = pools[_poolId];
        pool.metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    // transfers _poolAmt from msg.sender to the pool, and takes a fee
    function fundPool(uint256 _poolId, uint256 _poolAmt) external payable {
        // Implement the function here
    }

    /// @notice passes _data & msg.sender through to the allocation strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the allocation strategy for that pool
    function allocate(uint256 _poolId, bytes memory _data) external payable {
        pools[_poolId].allocationStrategy.allocate(_data, msg.sender);
    }

    // calls voting.generatePayouts() and then uses return data for payout.activatePayouts()
    // permissionless for anyone to call, checks happen within the strategies
    // check to make sure they haven't skrited around fee
    function finalize(uint256 _poolId, bytes memory _dataFromPoolOwner) external {
        // ASK: Do we need _dataFromPoolOwner to allow owner to pass custom data ?
        if (!registry.isMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }

        Pool memory pool = pools[_poolId];
        bytes memory dataFromAllocationStrategy = pool.allocationStrategy.generatePayouts();
        pool.disributionStrategy.activatePayouts(dataFromAllocationStrategy, _dataFromPoolOwner);
    }

    /// @notice passes _data & msg.sender through to the disribution strategy for that pool
    /// @param _poolId id of the pool
    /// @param _data encoded data unique to the disributionStrategy strategy for that pool
    function distribute(uint256 _poolId, bytes memory _data) external {
        if (!registry.isMemberOfIdentity(_identityId, msg.sender)) {
            revert NO_ACCESS_TO_ROLE();
        }
        pools[_poolId].disributionStrategy.distribute(_data, msg.sender);
    }

    /// @notice Closes the pool
    function closePool(uint256 _poolId) external {
        // pools[_poolId].allocationStrategy.close(); // ASK: Do we need this ?
        pools[_poolId].distributionStrategy.close();
        pools[_poolId].active = false;
        emit PoolClosed(_poolId);
    }

    /// @notice Updates the treasury address
    /// @dev Only callable by the owner
    function updateTreasury(address _treasury) external {
        treasury = _treasury;
    }
}
