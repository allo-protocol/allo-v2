// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract EventSetup {
    event Initialized(address allo, bytes32 profileId, uint256 poolId, bytes data);
    event Registered(address indexed recipientId, bytes data, address sender);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);
    event PoolActive(bool active);
    event RoleGranted(address indexed recipientId, address indexed account, bytes32 indexed role);
    event RoleAdminChanged(
        bytes32 indexed newAdminRole, address indexed recipientId, address indexed previousAdminRole
    );
    event TimestampsUpdated(
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 allocationStartTime,
        uint64 allocationEndTime,
        address sender
    );
    event PayoutSet(bytes recipientIds);
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);
    event TimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender);
    event NFTContractCreated(address nftContractAddress);
}
