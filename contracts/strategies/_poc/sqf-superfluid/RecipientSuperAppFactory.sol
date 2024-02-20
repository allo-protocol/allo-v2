// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    ISuperfluid,
    ISuperToken,
    SuperAppDefinitions
} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./RecipientSuperApp.sol";

contract RecipientSuperAppFactory {
    function createRecipientSuperApp(
        address _recipient,
        address _strategy,
        address _host,
        ISuperToken _acceptedToken,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted
    ) public returns (RecipientSuperApp recipientSuperApp) {
        ISuperfluid host = ISuperfluid(_host);

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

        recipientSuperApp = new RecipientSuperApp(_recipient, _strategy, _host, _acceptedToken);

        host.registerApp(recipientSuperApp, callBackDefinitions);
    }
}
