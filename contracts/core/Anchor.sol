// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Core Contracts
import {Registry} from "./Registry.sol";

/// @title Anchor contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice This contract is used to execute calls to a target address
// TODO: Fix this
/// @dev The Anhor is used as an identifier for your profile, it gives the protocol a way to send funds to a target
///      address and not get stuck in a contract.
contract Anchor {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice The registry contract on any given network/chain
    Registry public immutable registry;

    /// @notice The profileId of the allowed profile to execute calls
    bytes32 public profileId;

    /// ==========================
    /// ======== Errors ==========
    /// ==========================

    /// @dev Error when the caller is not the owner of the profile
    error UNAUTHORIZED();

    /// @dev Error when the call to the target address fails
    error CALL_FAILED();

    /// ==========================
    /// ======= Constructor ======
    /// ==========================

    /// @notice Construct a new Anchor contract
    /// @param _profileId The profileId of the allowed profile to execute calls
    /// @dev We also want to pass msg.sender to the Registry contract to set the owner
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
        // Check if the caller is the owner of the profile
        if (!registry.isOwnerOfProfile(profileId, msg.sender)) {
            revert UNAUTHORIZED();
        }

        // Call the target address and return the data
        (bool success, bytes memory data) = _target.call{value: _value}(_data);
        if (!success) {
            revert CALL_FAILED();
        }
        return data;
    }
}
