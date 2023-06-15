// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAqeduct {
    /**
        STORAGE (with public getters)
        address owner; // & all ownership transfer logic
        address allo;
    */

    // can receive ETH
    receive() external payable;

    // only way to spend ETH or tokens is to createPool
    // this first approves poolToken to allo, then calls allo.createPool() with _data
    function createPool(address _poolToken, bytes memory _data) external;
}