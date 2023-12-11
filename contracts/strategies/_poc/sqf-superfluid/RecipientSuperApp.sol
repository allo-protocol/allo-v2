// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SuperAppBaseSQF} from "./SuperAppBaseSQF.sol";
import {ISuperfluid} from "@superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperToken} from "@superfluid-contracts/interfaces/superfluid/ISuperToken.sol";
import {SQFSuperFluidStrategy} from "./SQFSuperFluidStrategy.sol";

contract RecipientSuperApp is SuperAppBaseSQF {
    error ZERO_ADDRESS();

    SQFSuperFluidStrategy public immutable strategy;

    constructor(
        address _strategy,
        address _host,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted,
        string memory _registrationKey
    )
        SuperAppBaseSQF(ISuperfluid(_host), _activateOnCreated, _activateOnUpdated, _activateOnDeleted, _registrationKey)
    {
        if (address(_strategy) == address(0)) {
            revert ZERO_ADDRESS();
        }
        strategy = SQFSuperFluidStrategy(_strategy);
    }

    /// @dev override if the SuperApp shall have custom logic invoked when an existing flow
    ///      to it is updated (flowrate change).
    function onFlowUpdated(
        ISuperToken, /*superToken*/
        address sender,
        address receiver,
        int96 previousFlowRate,
        int96 newFlowRate,
        uint256, /*lastUpdated*/
        bytes calldata ctx
    ) internal override returns (bytes memory /*newCtx*/ ) {
        // todo: clean function params
        // userData can be acquired with `host.decodeCtx(ctx).userData`

        strategy.adjustWeightings(previousFlowRate, newFlowRate);
        return ctx;
    }
}
