// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Strategy} from "./Strategy.sol";
import {AltRegistryGating} from "./modules/allocation/alt-registry/AltRegistryGating.sol";
import {Splitter} from "./modules/distribution/Splitter.sol";

contract AltRegistryGatingSplitter is Strategy, AltRegistryGating, Splitter {
    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external {
        super.initialize(_identityId, _poolId, _data);

        _setStrategyIdentifier("AltRegistryGatingSplitter");
    }

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {
        (,, address token,,,,) = allo.pools(poolId);
        Splitter._distribute(token, _recipientIds, _data, _sender);
    }
}
