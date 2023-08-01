// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract EventSetup {
    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);
    event Registered(address indexed recipientId, bytes data, address sender);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);
    event PoolActive(bool active);
}
