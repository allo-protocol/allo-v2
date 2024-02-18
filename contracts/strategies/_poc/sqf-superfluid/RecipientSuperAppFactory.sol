// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ISuperToken} from
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
        bool _activateOnDeleted,
        string memory _registrationKey
    ) public returns (RecipientSuperApp recipientSuperApp) {
        recipientSuperApp = new RecipientSuperApp(
        _recipient,
        _strategy,
        _host,
        _acceptedToken,
        _activateOnCreated,
        _activateOnUpdated,
        _activateOnDeleted,
        _registrationKey
        );
    }
}
