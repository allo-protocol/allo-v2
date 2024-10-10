// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {NFTGatingExtension} from "contracts/strategies/extensions/gating/NFTGatingExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract MockNFTGatingExtension is BaseStrategy, NFTGatingExtension {
    constructor(address _allo, string memory _strategyName) BaseStrategy(_allo, _strategyName) {}

    function initialize(uint256 _poolId, bytes memory) external virtual override {
        __BaseStrategy_init(_poolId);
    }

    function _checkOnlyWithNFT(address _nft, address _actor) internal view virtual override {
        super._checkOnlyWithNFT(_nft, _actor);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal virtual override {}

    function _distribute(address[] memory, bytes memory, address) internal virtual override {}

    function _register(address[] memory, bytes memory, address) internal virtual override returns (address[] memory) {}
}
