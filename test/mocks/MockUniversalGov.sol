// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract MockUniversalGov {
    mapping(address => uint256) public gov;

    function add(address _gov, uint256 _value) external {
        gov[_gov] = _value;
    }

    function getPriorVotes(address _account, uint256 _blockNumber) external view returns (uint96) {
        _blockNumber;
        return uint96(gov[_account]);
    }

    function getPastVotes(address _account, uint256 _timestamp) external view returns (uint256) {
        _timestamp;
        return gov[_account];
    }
}
