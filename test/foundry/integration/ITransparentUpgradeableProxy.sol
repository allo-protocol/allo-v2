// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITransparentUpgradeableProxy {
    function admin() external view returns (address);

    function implementation() external view returns (address);

    function changeAdmin(address) external;

    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}
