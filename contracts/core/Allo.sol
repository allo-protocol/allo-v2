// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {MetaPtr} from "../utils/MetaPtr.sol";
import {IAllo} from "./interfaces/IAllo.sol";
// import {IAllo} from "./interfaces/IAllo.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Allo is Initializable, IAllo {
    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize() public reinitializer(1) {}

    // External functions

    function getPoolInfo(
        uint256 _poolId
    ) external view override returns (PoolData memory, string memory) {
        // Implement the function here
    }

    // todo: update pure back to view when we have the implementation done.
    function createPool(
        PoolData memory /*_poolData*/
    ) external pure override returns (uint) {
        uint32 _poolId = 0;

        // todo: return the poolId? what do we want to return here?
        return _poolId;
    }

    function applyToPool(
        uint _poolId,
        bytes memory _data
    ) external payable override returns (uint) {
        // Implement the function here
    }

    function updateMetadata(
        uint _poolId,
        bytes memory _data
    ) external payable override returns (bytes memory) {
        // Implement the function here
    }

    function fundPool(
        uint _poolId,
        uint _poolAmt
    ) external payable override {
        // Implement the function here
    }

    function allocate(
        uint _poolId,
        bytes memory _data
    ) external payable override {
        // Implement the function here
    }

    function finalize(uint _poolId) external override {
        // Implement the function here
    }

    function distribute(uint _poolId, bytes memory _data) external override {
        // Implement the function here
    }

    function closePool(uint _poolId) external override {
        // Implement the function here
    }
}
