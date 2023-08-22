// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Registry} from "./Registry.sol";

contract Anchor {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================
    Registry public immutable registry;
    bytes32 public immutable profileId;

    /// ==========================
    /// ======== Errors ==========
    /// ==========================
    error UNAUTHORIZED();
    error CALL_FAILED();

    /// ==========================
    /// ======= Constructor ======
    /// ==========================
    constructor(bytes32 _profileId) {
        registry = Registry(msg.sender);
        profileId = _profileId;
    }

    /// ==========================
    /// ======== External ========
    /// ==========================

    /// @notice Execute a call to a target address
    /// @param _target The target address to call
    /// @param _value The amount of native token to send
    /// @param _data The data to send to the target address
    function execute(address _target, uint256 _value, bytes memory _data) external returns (bytes memory) {
        if (!registry.isOwnerOfProfile(profileId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        if (_target == address(this)) {
            revert CALL_FAILED();
        }

        (bool success, bytes memory data) = _target.call{value: _value}(_data);
        if (!success) {
            revert CALL_FAILED();
        }
        return data;
    }
}
