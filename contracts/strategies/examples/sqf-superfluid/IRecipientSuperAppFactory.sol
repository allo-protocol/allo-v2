// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

interface IRecipientSuperAppFactory {
    function createRecipientSuperApp(
        address _recipient,
        address _strategy,
        address _host,
        ISuperToken _acceptedToken,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted
    ) external returns (address recipientSuperApp);
}
