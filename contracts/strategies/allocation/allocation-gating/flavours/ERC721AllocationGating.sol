// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// import "../AllocationGating.sol";
// import {Allo} from "../../../../core/Allo.sol";

// import "@openzeppelin/token/ERC721/IERC721.sol";

// contract ERC721AllocationGating is AllocationGating {
//     /// =================================
//     /// === Custom Storage Variables ====
//     /// =================================

//     IERC721 public token;

//     /// ====================================
//     /// =========== Functions ==============
//     /// ====================================

//     // todo: fix this...
//     constructor() AllocationGating(address(0)) {}

//     /// @notice Initializes the allocation strategy
//     /// @param _allo Address of the Allo contract
//     /// @param _identityId Id of the identity
//     /// @param _poolId Id of the pool
//     /// @param _data The data to be decoded
//     /// @dev This function is called by the Allo contract
//     function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public {
//         // __BaseAllocationStrategy_init("ERC721AllocationGatingV1", _allo, _identityId, _poolId, _data);
//         BaseStrategy(_allo).initialize(_identityId, _poolId, _data);

//         // decode data custom to this strategy
//         (address _token) = abi.decode(_data, (address));
//         token = IERC721(_token);
//     }

//     /// @notice Checks if recipient owns ERC721 token
//     /// @param _recipient Address of the recipient
//     function _isEligibleForAllocation(address _recipient) internal view override returns (bool) {
//         return token.balanceOf(_recipient) > 0;
//     }

//     function skim(address _token) external override {}

//     function isValidAllocater(address _voter) external view override returns (bool) {}

//     function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external override {}
// }
