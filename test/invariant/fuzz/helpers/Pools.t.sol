// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import {Allo, IAllo} from "contracts/core/Allo.sol";

import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";
import {DonationVotingOnchain} from "contracts/strategies/examples/donation-voting/DonationVotingOnchain.sol";
import {EasyRPGF} from "contracts/strategies/examples/easy-rpgf/EasyRPGF.sol";
import {QVImpactStream} from "contracts/strategies/examples/impact-stream/QVImpactStream.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";
import {RFPSimple} from "contracts/strategies/examples/rfp/RFPSimple.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";

contract Pools is Utils {
    Allo private allo;

    enum PoolStrategies {
        None,
        DirectAllocation,
        DonationVoting,
        EasyRPGF,
        ImpactStream,
        QuadraticVoting,
        RFP,
        SQFSuperfluid
    }

    uint256[] internal ghost_poolIds;
    mapping(uint256 _poolId => address _poolAdmin) ghost_poolAdmins;

    // mapping(uint256 _poolId => PoolStrategies _strategy) internal _poolStrategy;

    mapping(PoolStrategies _strategy => address _implementation)
        internal _strategyImplementations;

    function _initImplementations(address _allo) internal {
        _strategyImplementations[PoolStrategies.DirectAllocation] = address(
            new DirectAllocationStrategy(_allo)
        );
        _strategyImplementations[PoolStrategies.DonationVoting] = address(
            new DonationVotingOnchain(_allo, "MyFancyName")
        );
        _strategyImplementations[PoolStrategies.EasyRPGF] = address(
            new EasyRPGF(_allo)
        );
        _strategyImplementations[PoolStrategies.ImpactStream] = address(
            new QVImpactStream(_allo)
        );
        _strategyImplementations[PoolStrategies.QuadraticVoting] = address(
            new QVSimple(_allo, "MyFancyName")
        );
        _strategyImplementations[PoolStrategies.RFP] = address(
            new RFPSimple(_allo)
        );
        _strategyImplementations[PoolStrategies.SQFSuperfluid] = address(
            new SQFSuperfluid(_allo)
        );

        allo = Allo(_allo);
    }

    function _recordPool(uint256 _poolId, PoolStrategies _strategy) internal {
        // _poolStrategy[_poolId] = _strategy;
        ghost_poolIds.push(_poolId);
    }

    // reverse lookup pool id -> strategy type
    function _poolStrategy(uint256 _poolId) internal returns (PoolStrategies) {
        IAllo.Pool memory _pool = allo.getPool(_poolId);
        for (uint256 i; i < uint256(type(PoolStrategies).max); i++)
            if (
                _strategyImplementations[PoolStrategies(i)] ==
                address(_pool.strategy)
            ) return PoolStrategies(i);

        emit TestFailure("Wrong pool strategy implementation address");
    }

    function _strategyHasImplementation(
        PoolStrategies _strategy
    ) internal returns (bool) {
        for (uint256 i; i < ghost_poolIds.length; i++) {
            if (_poolStrategy(ghost_poolIds[i]) == _strategy) return true;
        }

        return false;
    }
}
