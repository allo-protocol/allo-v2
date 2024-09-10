// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface ISuperfluidGovernance {
    function owner() external view returns (address);
    function setAppRegistrationKey(address host, address deployer, string memory registrationKey, uint256 expirationTs)
        external;
}
