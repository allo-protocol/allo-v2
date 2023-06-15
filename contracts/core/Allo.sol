// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {MetaPtr} from "../utils/MetaPtr.sol";
// import {IRegistry} from "./interfaces/IRegistry.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Allo is Initializable {
    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize() public reinitializer(1) {}
}
