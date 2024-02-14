// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockERC20Permit is ERC20, ERC20Permit {
    constructor()
        ERC20("Mock Permit", "MOCK_PERMIT")
        ERC20Permit("Mock Permit")
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
