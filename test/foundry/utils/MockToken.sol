// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

contract MockToken is ERC20, ERC20Permit {
    constructor() ERC20("Mock Token", "MTK") ERC20Permit("Mock Token") {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
