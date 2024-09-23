// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {TokenGatingExtension} from "contracts/strategies/extensions/gating/TokenGatingExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract MockTokenGatingExtension is BaseStrategy, TokenGatingExtension {
    constructor(address _allo) BaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory) external virtual override {
        __BaseStrategy_init(_poolId);
    }

    function _checkOnlyWithToken(address _token, uint256 _amount, address _actor) internal view virtual override {
        super._checkOnlyWithToken(_token, _amount, _actor);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal virtual override {}

    function _distribute(address[] memory, bytes memory, address) internal virtual override {}

    function _register(address[] memory, bytes memory, address) internal virtual override returns (address[] memory) {}
}
