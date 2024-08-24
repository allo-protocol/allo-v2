// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IDAI {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
