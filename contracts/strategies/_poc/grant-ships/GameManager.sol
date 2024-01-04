// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";

// SubStrategy Contracts
import {GrantShipStrategy} from "./GrantShipStrategy.sol";

contract GameManager is BaseStrategy, ReentrancyGuard {
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
    address token;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;

    mapping(address => GrantShipStrategy) public grantShips;
    mapping(address => GrantShipRecipient) public grantShipRecipients;

    uint256 gameFacilitatorHatId;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ======== Initialize ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        (bytes memory _gameParams, bytes[] memory _startingShips) = abi.decode(_data, (bytes, bytes[]));

        __gameState_init(_gameParams);
        // __grantShips_init(_startingShips);
    }

    function __gameState_init(bytes memory _gameParams) internal {
        // TODO: refactor if only 2 setup params
        (uint256 _gameFacilitatorId, address _token, address _hatsAddress) =
            abi.decode(_gameParams, (uint256, address, address));

        gameFacilitatorHatId = _gameFacilitatorId;
        token = _token;
        _hats = IHats(_hatsAddress);
    }

    function __grantShips_init() internal {
        // loop over grantship data
        // create each grantship
        // register each grantship?
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

    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {
        // onlyFacilitator
        // register each grantship
    }

    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {}

    function _getGrantShipRecipient(address _recipientId) public view returns (GrantShipRecipient memory) {
        GrantShipRecipient memory grantShipRecipient = grantShipRecipients[_recipientId];

        return grantShipRecipient;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        GrantShipRecipient memory shipRecipient = _getGrantShipRecipient(_recipientId);
        return PayoutSummary(address(shipRecipient.recipientAddress), shipRecipient.grantAmount);
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return _hats.isWearerOfHat(_allocator, gameFacilitatorHatId);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
