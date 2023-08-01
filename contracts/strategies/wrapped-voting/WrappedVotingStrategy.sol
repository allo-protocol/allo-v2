// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
// Interfaces
import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

contract WrappedVotingStrategy is BaseStrategy, ReentrancyGuard {
    enum InternalRecipientStatus {
        Pending,
        Accepted,
        Rejected
    }

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function initialize(uint256 _poolId, bytes memory) external {
        __WrappedVotingStrategy_init(_poolId);
    }

    function __WrappedVotingStrategy_init(uint256 _poolId) internal {
        __BaseStrategy_init(_poolId);
    }

    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    function getRecipientStatus(address _recipientId) external pure override returns (RecipientStatus) {
        return RecipientStatus.Accepted; // Mock value
    }

    function getPayouts(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        pure
        override
        returns (PayoutSummary[] memory)
    {
        // Implement logic here
    }

    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address) {
        return _registerRecipient(_data, _sender);
    }

    function _allocate(bytes memory _data, address _sender) internal override {
        return _allocate(_data, _sender);
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {
        return _distribute(_recipientIds, _data, _sender);
    }
}
