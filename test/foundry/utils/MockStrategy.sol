// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// import "../../../contracts/strategies/BaseStrategy.sol";

// contract MockStrategy is BaseStrategy {
//     struct PayoutSummary {
//         address recipient;
//         uint256 amount;
//         uint256 percentage;
//     }

//     constructor(address _allo) BaseStrategy(_allo) {}

//     function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) external {
//         // __BaseAllocationStrategy_init("MockAllocation", _allo, _identityId, _poolId, _data);
//         BaseStrategy(_allo).initialize( _poolId, _data);
//     }

//     function skim(address _token) external override {}

//     function registerRecipients(bytes memory _data, address _sender) external payable returns (address) {
//         return address(1);
//     }

//     function getRecipientStatus(address) external view override returns (RecipientStatus) {}

//     function isValidAllocater(address _voter) external view override returns (bool) {}

//     function allocate(bytes memory, address) external payable override {}

//     function getPayout(address[] memory, bytes memory) external view returns (PayoutSummary[] memory summaries) {}

//     function readyToPayout(bytes calldata) external view returns (bool) {}

//     function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external override {}
// }
