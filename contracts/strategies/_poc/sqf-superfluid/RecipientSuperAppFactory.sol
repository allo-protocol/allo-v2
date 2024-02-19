// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ISuperToken} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./RecipientSuperApp.sol";

contract RecipientSuperAppFactory {
    address deployer;
    string registrationKey;

    constructor() {
        deployer = msg.sender;
    }

    function setRegistrationKey(string memory _registrationKey) external {
        require(msg.sender == deployer, "Only deployer may set registration key");
        registrationKey = _registrationKey;
    }

    function createRecipientSuperApp(
        address _recipient,
        address _strategy,
        address _host,
        ISuperToken _acceptedToken,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted
    ) public returns (RecipientSuperApp recipientSuperApp) {
        recipientSuperApp = new RecipientSuperApp(
            _recipient,
            _strategy,
            _host,
            _acceptedToken,
            _activateOnCreated,
            _activateOnUpdated,
            _activateOnDeleted,
            registrationKey
        );
    }
}
