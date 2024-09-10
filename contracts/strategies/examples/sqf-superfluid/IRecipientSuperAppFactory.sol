// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

interface IRecipientSuperAppFactory {
    /// @dev Create a new recipient super app
    /// @param _recipient The recipient address
    /// @param _strategy The strategy address
    /// @param _host The host address
    /// @param _acceptedToken The accepted token
    /// @param _activateOnCreated Whether to activate on created
    /// @param _activateOnUpdated Whether to activate on updated
    /// @param _activateOnDeleted Whether to activate on deleted
    /// @return recipientSuperApp The recipient super app address
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
