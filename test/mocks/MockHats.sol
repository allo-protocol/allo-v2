// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

contract MockHats {
    mapping(address => bool) public hats;

    function addHat(address _hat, bool _flag) external {
        hats[_hat] = _flag;
    }

    function isWearerOfHat(address _account, uint256 _id) external view returns (bool) {
        _id;
        return hats[_account];
    }
}
