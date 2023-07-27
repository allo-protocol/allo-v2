// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract EventSetup {
    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);
    event Skim(address skimmer, address token, uint256 amountToTreasury, uint256 amountToSkimmer);
    event Registered(address indexed recipientId, bytes data, address sender);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);
    event PoolActive(bool active);
    event Appealed(address indexed recipientId, bytes data, address sender);
    event RoleGranted(address indexed recipientId, address indexed account, bytes32 indexed role);
    event RoleAdminChanged(
        bytes32 indexed newAdminRole, address indexed recipientId, address indexed previousAdminRole
    );
    event TimestampsUpdated(
        address indexed recipientId,
        uint256 registrationStartTime,
        uint256 registrationEndTime,
        uint256 allocationStartTime,
        uint256 allocationEndTime
    );
    event PayoutSet(bytes recipientIds);
}
