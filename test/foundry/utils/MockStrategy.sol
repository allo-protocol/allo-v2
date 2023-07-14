// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../../contracts/strategies/Strategy.sol";

contract MockStrategy is Strategy {
    function initialize(bytes32 _ownerIdentityId, uint256 _poolId, bytes memory _data) external {
        super.initialize(_ownerIdentityId, _poolId, _data);
    }

    function registerRecipients(bytes memory _data, address _sender) external payable returns (address) {
        return address(1);
    }

    function getRecipientStatus(address) external view override returns (RecipientStatus) {}

    function isValidAllocater(address) external view override returns (bool) {}

    function allocate(bytes memory, address) external payable override {}

    function getRecipientPayout(address[] memory, bytes memory) external view returns (Payout[] memory summaries) {}

    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external override {}
}
