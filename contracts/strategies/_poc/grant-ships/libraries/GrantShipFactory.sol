// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract GrantShipFactory {
    address public immutable template;

    constructor(address _template) {
        template = _template;
    }

    function create() external returns (address) {
        address clone = Clones.clone(template);
        return clone;
    }
}
