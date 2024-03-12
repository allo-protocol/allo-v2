// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

abstract contract IVotable {
    address public votingStrategy;

    function vote(bytes[] memory data) external payable virtual;
}
