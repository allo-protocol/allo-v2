// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IRecipientSuperAppFactory} from "contracts/strategies/interfaces/IRecipientSuperAppFactory.sol";
import {RecipientSuperApp} from "contracts/strategies/RecipientSuperApp.sol";

contract RecipientSuperAppFactory is IRecipientSuperAppFactory {
    function createRecipientSuperApp(
        address _recipient,
        address _strategy,
        address _host,
        ISuperToken _acceptedToken,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted
    ) public returns (address recipientSuperApp) {
        uint256 callBackDefinitions =
            SuperAppDefinitions.APP_LEVEL_FINAL | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;

        if (!_activateOnCreated) {
            callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
        }

        if (!_activateOnUpdated) {
            callBackDefinitions |=
                SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
        }

        if (!_activateOnDeleted) {
            callBackDefinitions |= SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
                | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
        }

        recipientSuperApp = address(new RecipientSuperApp(_recipient, _strategy, _host, _acceptedToken));

        ISuperfluid(_host).registerApp(ISuperApp(recipientSuperApp), callBackDefinitions);
    }
}
