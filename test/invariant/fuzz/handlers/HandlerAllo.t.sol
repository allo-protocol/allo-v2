// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";
import {IAllo, Metadata} from "contracts/core/Allo.sol";

contract HandlerAllo is Setup {
    uint256[] ghost_poolIds;

    function handler_createPool(uint256 _msgValue) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            _ghost_anchorOf[msg.sender]
        );

        // Avoid EOA
        if (profile.anchor == address(0)) return;

        // Create a pool
        (bool succ, bytes memory ret) = targetCall(
            address(allo),
            _msgValue,
            abi.encodeWithSelector(
                IAllo.createPool.selector,
                profile.id,
                address(strategy_directAllocation),
                bytes(""),
                address(token),
                0,
                profile.metadata,
                new address[](0)
            )
        );

        if (succ) ghost_poolIds.push(abi.decode(ret, (uint256)));
    }

    function handler_updatePoolMetadata(
        uint256 _idSeed,
        uint256 _metadataProtocol,
        string calldata _data
    ) public {
        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        _idSeed = _idSeed % ghost_poolIds.length;
        uint256 poolId = ghost_poolIds[_idSeed];

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            _ghost_anchorOf[msg.sender]
        );

        // Avoid EOA
        if (profile.anchor == address(0)) return;

        Metadata memory metadata = Metadata({
            protocol: _metadataProtocol,
            pointer: _data
        });

        // Update the pool metadata - will revert on wrong anchor
        targetCall(
            address(allo),
            0,
            abi.encodeWithSelector(
                IAllo.updatePoolMetadata.selector,
                poolId,
                metadata
            )
        );
    }

    function handler_updatePercentFee(uint256 _newPercentFee) public {
        _newPercentFee = bound(_newPercentFee, 0, 1e18);

        // Update the percent fee - will revert if wrong caller
        targetCall(
            address(allo),
            0,
            abi.encodeWithSelector(
                IAllo.updatePercentFee.selector,
                _newPercentFee
            )
        );
    }

    function handler_updateBaseFee(uint256 _newBaseFee) public {
        // Update the base fee - will revert if wrong caller
        targetCall(
            address(allo),
            0,
            abi.encodeWithSelector(IAllo.updateBaseFee.selector, _newBaseFee)
        );
    }
}
