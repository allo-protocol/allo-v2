// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface ISuperfluidGovernance {
    /// @dev Returns the owner of the contract
    /// @return The owner of the contract
    function owner() external view returns (address);

    /// @dev Sets the app registration key
    /// @param host The host address
    /// @param deployer The deployer address
    /// @param registrationKey The registration key
    /// @param expirationTs The expiration timestamp
    function setAppRegistrationKey(address host, address deployer, string memory registrationKey, uint256 expirationTs)
        external;
}
