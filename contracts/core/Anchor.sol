// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Registry} from "./Registry.sol";

contract Anchor {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================
    Registry immutable registry;
    bytes32 public identityId;

    /// ==========================
    /// ======== Errors ==========
    /// ==========================
    error UNAUTHORIZED();
    error ALREADY_INITIALIZED();
    error CALL_FAILED();

    /// ==========================
    /// ======= Constructor ======
    /// ==========================
    constructor(address _registry) {
        registry = Registry(_registry);
    }

    /// ==========================
    /// ======== External ========
    /// ==========================

    /// @notice Initialize the Anchor
    /// @param _identityId The identityId of the identity to anchor
    function initialize(bytes32 _identityId) external {
        if (msg.sender != address(registry)) {
            revert UNAUTHORIZED();
        }

        if (identityId != "") {
            revert ALREADY_INITIALIZED();
        }
        identityId = _identityId;
    }

    /// @notice Execute a call to a target address
    /// @param _target The target address to call
    /// @param _value The amount of native token to send
    /// @param _data The data to send to the target address
    function execute(address _target, uint256 _value, bytes memory _data) external returns (bytes memory) {
        if (!registry.isOwnerOfIdentity(identityId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        (bool success, bytes memory data) = _target.call{value: _value}(_data);
        if (!success) {
            revert CALL_FAILED();
        }
        return data;
    }
}
