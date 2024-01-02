// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";

// Internal Libraries
import {Metadata} from "../../../core/libraries/Metadata.sol";

contract GrantShip is BaseStrategy, ReentrancyGuard {

constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}
function _allocate(bytes memory _data, address _sender) internal virtual override {}
function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual override{}
function _getPayout(address _recipientId, bytes memory _data) internal view override returns (PayoutSummary memory) {}
function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {}
function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {}
function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address){}
function initialize(uint256 _poolId, bytes memory _data) external {}


}