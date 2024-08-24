// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockERC20Permit is ERC20, ERC20Permit {
    constructor() ERC20("Test", "TEST") ERC20Permit("Test") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
