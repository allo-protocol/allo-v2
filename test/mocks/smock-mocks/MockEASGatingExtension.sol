// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {EASGatingExtension} from "contracts/strategies/extensions/gating/EASGatingExtension.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

contract MockEASGatingExtension is BaseStrategy, EASGatingExtension {
    constructor(address _allo) BaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        __EASGatingExtension_init(abi.decode(_data, (address)));
    }

    function __EASGatingExtension_init(address _eas) internal virtual override {
        super.__EASGatingExtension_init(_eas);
    }

    function _checkOnlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid)
        internal
        view
        virtual
        override
    {
        super._checkOnlyWithAttestation(_schema, _attester, _uid);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal virtual override {}

    function _distribute(address[] memory, bytes memory, address) internal virtual override {}

    function _register(address[] memory, bytes memory, address) internal virtual override returns (address[] memory) {}
}
