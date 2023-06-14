// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { IRegistry } from "./interfaces/IRegistry.sol";

import "openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Registry {
    mapping(bytes32 => address) public registry;

    function register(bytes32 _name, address _addr) external {
        registry[_name] = _addr;
    }

    function get(bytes32 _name) external view returns (address) {
        return registry[_name];
    }
}
