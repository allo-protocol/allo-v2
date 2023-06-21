// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {MetaPtr} from "../../utils/MetaPtr.sol";

/// @dev This is the interface for the Allo core contract
interface IAllo {
    /**
        STORAGE (with public getters)
        uint fees;
        address treasury;
        address registry; // must be editable to be ready for cross chain upgrades
        mapping (uint256 => PoolData) pools;
    */

    struct PoolData {
        address owner;
        address identity; // do we need this? and should it be an address?
        address allocationStrategy;
        address distributionStrategy;
        MetaPtr metadata;
        bool active;
    }

    // Public getter on the pools mapping
    /// @notice calls out to the registry to get the identity metadata
    function getPoolInfo(
        uint _poolId
    ) external view returns (PoolData memory, string memory);

    // @todo insert clonable strategy library, including validation that an existing pool has safe strategy

    // creates pool locally, transfers pool amount to distribution strategy => returns poolId
    // takes fee from user
    // validates that the owner is actually allowed to use the identity
    function createPool(PoolData memory _poolData) external view returns (uint);

    // passes _data & msg.sender through to the allocation strategy for that pool
    function applyToPool(uint _poolId, bytes memory _data) external payable;

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here?
    function updateMetadata(
        uint _poolId,
        bytes memory _data
    ) external payable returns (bytes memory);

    // transfers _poolAmt from msg.sender to the pool, and takes a fee
    function fundPool(
        uint _poolId,
        uint _poolAmt
    ) external payable;

    // passes _data & msg.sender through to the allocation strategy for that pool
    function allocate(uint _poolId, bytes memory _data) external payable;

    // calls voting.generatePayouts() and then uses return data for payout.activatePayouts()
    // permissionless for anyone to call, checks happen within the strategies
    // check to make sure they haven't skrited around fee
    function finalize(uint _poolId) external;

    // call to payoutStrategy.claim()
    function claim(uint _poolId, bytes memory _data) external;

    // call to distributionStrategy.close()
    function closePool(uint _poolId) external;
}
