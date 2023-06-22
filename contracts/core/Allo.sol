// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Metadata } from "./libraries/Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Allo is Initializable {
    struct PoolData {
        address identity;
        address allocationStrategy;
        address distributionStrategy;
        Metadata metadata;
        bool active;
    }

    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize() public reinitializer(1) {}

    // Public getter on the pools mapping
    /// @notice calls out to the registry to get the identity metadata
    function getPoolInfo(
        uint256 _poolId
    ) external view returns (PoolData memory, string memory) {
        // Implement the function here
    }

    // @todo insert clonable strategy library, including validation that an existing pool has safe strategy

    // creates pool locally, transfers pool amount to distribution strategy => returns poolId
    // takes fee from user
    // validates that the owner is actually allowed to use the identity
    function createPool(
        PoolData memory /*_poolData*/
    ) external pure returns (uint) {
        uint32 _poolId = 0;

        // todo: return the poolId? what do we want to return here?
        return _poolId;
    }

    // passes _data & msg.sender through to the allocation strategy for that pool
    // it should return a uint that represents the application
    function applyToPool(
        uint _poolId,
        bytes memory _data
    ) external payable returns (uint) {
        // Implement the function here
    }

    // decode the _data into what's relevant for this strategy
    // perform whatever actions are necessary (token transfers, storage updates, etc)
    // all approvals, checks, etc all happen within internal functions from here?
    function updateMetadata(
        uint _poolId,
        bytes memory _data
    ) external payable returns (bytes memory) {
        // Implement the function here
    }

    // transfers _poolAmt from msg.sender to the pool, and takes a fee
    function fundPool(uint _poolId, uint _poolAmt) external payable {
        // Implement the function here
    }

    // passes _data & msg.sender through to the allocation strategy for that pool
    function allocate(uint _poolId, bytes memory _data) external payable {
        // Implement the function here
    }

    // calls voting.generatePayouts() and then uses return data for payout.activatePayouts()
    // permissionless for anyone to call, checks happen within the strategies
    // check to make sure they haven't skrited around fee
    function finalize(uint _poolId) external {
        // Implement the function here
    }

    // call to payoutStrategy.distribute()
    function distribute(uint _poolId, bytes memory _data) external {
        // Implement the function here
    }

    // call to distributionStrategy.close()
    function closePool(uint _poolId) external {
        // Implement the function here
    }
}
