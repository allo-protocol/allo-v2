// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface UniversalGov {
    function getPriorVotes(address _account, uint256 _blockNumber) external view returns (uint96);
    function getPastVotes(address _account, uint256 _timestamp) external view returns (uint256);
}
