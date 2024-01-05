// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";

// SubStrategy Contracts
import {GrantShipStrategy} from "./GrantShipStrategy.sol";

contract GameManagerStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Models ==============
    /// ================================

    struct GrantShipRecipient {
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        Status recipientStatus;
    }

    /// ===============================
    /// ======== Game State ===========
    /// ===============================

    uint256 public currentRoundId;
    uint256 public currentRoundStartTime;
    uint256 public currentRoundEndTime;
    Status public currentRoundStatus;

    address public token;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;
    IAllo private _allo;

    mapping(address => GrantShipStrategy) public grantShips;
    mapping(address => GrantShipRecipient) public grantShipRecipients;

    uint256 public gameFacilitatorHatId;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _alloAddress, string memory _name) BaseStrategy(_alloAddress, _name) {}

    /// ===============================
    /// ======== Initialize ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        (bytes memory _gameParams, bytes[] memory _shipData) = abi.decode(_data, (bytes, bytes[]));

        __gameState_init(_gameParams);
        // __grantShips_init(_shipData, strategyImpl);
    }

    function __gameState_init(bytes memory _gameParams) internal {
        // TODO: refactor if only 2 setup params
        (uint256 _gameFacilitatorId, address _token, address _hatsAddress) =
            abi.decode(_gameParams, (uint256, address, address));

        gameFacilitatorHatId = _gameFacilitatorId;
        token = _token;
        _hats = IHats(_hatsAddress);
    }

    function __grantShips_init(bytes[] memory _shipData) internal {}

    function acceptGrantShip(address _recipientId, bytes memory _data) external {
        // onlyFacilitator
        // only if recipient is in pending status
        // only
    }

    function _allocate(bytes memory _data, address _sender) internal virtual override {
        // onlyFacilitator
        // takes an array of amounts
        // checks if the amount of percentages is 100%
        // checks if array of the percentages is the same length as the array of the ships

        // allocates funding to each grantship
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
    {
        // onlyFacilitator
        // transfer token amounts to each grantShip pool.

        // distributes funding to each grantship
    }

    /// ====================================
    /// ============ View ==================
    /// ====================================

    function isGameFacilitator(address _address) internal view returns (bool) {
        return _hats.isWearerOfHat(_address, gameFacilitatorHatId);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _createGrantShipStrategy(address _strategyImpl, bytes memory _data, uint256 grantShipNumber)
        internal
        returns (address payable)
    {}

    function _beforeRegisterRecipient(bytes memory, address _sender) internal view override {
        if (!isGameFacilitator(_sender)) revert UNAUTHORIZED();
    }

    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {}

    // function _beforeAllocate(bytes memory, address _sender) internal view override {
    //     if (!isGameManager(_sender)) revert UNAUTHORIZED();
    // }

    // function _beforeDistribute(address[] memory, bytes memory, address _sender) internal view override {
    //     if (!isGameManager(_sender)) revert UNAUTHORIZED();
    // }

    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
        GrantShipRecipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        return grantShipRecipient.recipientStatus;
    }

    function _getGrantShipRecipient(address _recipientId) public view returns (GrantShipRecipient memory) {
        GrantShipRecipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        return grantShipRecipient;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        GrantShipRecipient memory shipRecipient = _getGrantShipRecipient(_recipientId);
        return PayoutSummary(address(shipRecipient.recipientAddress), shipRecipient.grantAmount);
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        // return isGameManager(_allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
