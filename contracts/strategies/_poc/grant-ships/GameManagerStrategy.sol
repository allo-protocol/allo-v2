// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol"; //remove after testing

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../../core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {Allo} from "../../../../contracts/core/Allo.sol";

// SubStrategy Contracts
import {GrantShipStrategy} from "./GrantShipStrategy.sol";

contract GameManagerStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Models ==============
    /// ================================

    struct Recipient {
        address teamAddress;
        address payable recipientAddress;
        uint256 shipPoolId;
        uint256 grantAmount;
        Metadata metadata;
        Status recipientStatus;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when the milestone is invalid.
    error INVALID_STATUS();

    /// ===============================
    /// ========== Modifiers ==========
    /// ===============================

    modifier onlyGameFacilitator(address _sender) {
        _hats.isWearerOfHat(_sender, gameFacilitatorHatId);
        _;
    }

    /// ===============================
    /// ======== Game State ===========
    /// ===============================

    uint256 public currentRoundId;
    uint256 public currentRoundStartTime;
    uint256 public currentRoundEndTime;
    Status public currentRoundStatus;

    address public token;
    address public gameManager;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;
    Allo private _allo;

    ///@notice This maps the teamAddress to the recipient
    ///@dev 'teamAddress' to 'Recipient'
    mapping(address => Recipient) public grantShipRecipients;

    uint256 public gameFacilitatorHatId;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _alloAddress, string memory _name) BaseStrategy(_alloAddress, _name) {
        _allo = Allo(_alloAddress);
    }

    /// ===============================
    /// ======== Initialize ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        (bytes memory _gameParams, bytes[] memory _shipData) = abi.decode(_data, (bytes, bytes[]));

        __gameState_init(_gameParams);
        __grantShips_init(_shipData);
    }

    function __gameState_init(bytes memory _gameParams) internal {
        // TODO: refactor if only 2 setup params
        (uint256 _gameFacilitatorId, address _token, address _hatsAddress, address _gameManager) =
            abi.decode(_gameParams, (uint256, address, address, address));

        gameFacilitatorHatId = _gameFacilitatorId;
        token = _token;
        _hats = IHats(_hatsAddress);
        gameManager = _gameManager;
    }

    function __grantShips_init(bytes[] memory _shipData) internal {
        IRegistry registry = _allo.getRegistry();

        // registerShip

        for (uint256 i = 0; i < _shipData.length; i++) {
            (string memory _shipName, Metadata memory _shipMetadata, address _teamAddress, uint256 _facilitatorId) =
                abi.decode(_shipData[i], (string, Metadata, address, uint256));

            // Note:
            // Would be nice to have the captain address as a manager
            // but owner has to be msg.sender in order to create a manager.
            // can always do it in a separate call later.

            address[] memory profileManagers = new address[](2);
            profileManagers[0] = _teamAddress;
            profileManagers[1] = gameManager;

            address[] memory poolAdminAsManager = new address[](1);
            poolAdminAsManager[0] = gameManager;

            bytes32 shipProfileId =
                registry.createProfile(i + 1, _shipName, _shipMetadata, address(this), profileManagers);

            GrantShipStrategy grantShip = new GrantShipStrategy(address(allo), "Grant Ship Strategy");
            address payable strategyAddress = payable(address(grantShip));

            uint256 shipPoolId = _allo.createPoolWithCustomStrategy(
                shipProfileId,
                strategyAddress,
                abi.encode(true, true, true, _facilitatorId),
                token,
                0,
                _shipMetadata,
                // pool manager/game facilitator role will be mediated through Hats Protocol
                // pool_admin address will be the game_facilitator multisig
                // using pool_admin as a single address for both roles
                poolAdminAsManager
            );

            unchecked {
                i++;
            }

            Recipient memory newShipRecipient =
                Recipient(_teamAddress, strategyAddress, shipPoolId, 0, _shipMetadata, Status.Pending);

            grantShipRecipients[_teamAddress] = newShipRecipient;
        }
    }

    function approveShips(address[] memory _shipAddresses) external onlyGameFacilitator(msg.sender) {
        uint256 shipLength = _shipAddresses.length;
        for (uint256 i = 0; i < shipLength; i++) {
            Recipient storage shipRecipient = grantShipRecipients[_shipAddresses[i]];

            if (shipRecipient.recipientStatus != Status.Pending) revert INVALID_STATUS();

            shipRecipient.recipientStatus = Status.Accepted;
        }
    }

    function rejectShips(address[] memory _shipAddresses) external onlyGameFacilitator(msg.sender) {
        uint256 shipLength = _shipAddresses.length;
        for (uint256 i = 0; i < shipLength; i++) {
            Recipient storage shipRecipient = grantShipRecipients[_shipAddresses[i]];

            if (shipRecipient.recipientStatus != Status.Pending) revert INVALID_STATUS();

            shipRecipient.recipientStatus = Status.Rejected;
        }
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

    function isGameFacilitator(address _address) public view returns (bool) {
        return _hats.isWearerOfHat(_address, gameFacilitatorHatId);
    }

    function getStrategyAddress(address _teamAddress) public view returns (address payable) {
        return grantShipRecipients[_teamAddress].recipientAddress;
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
        Recipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        return grantShipRecipient.recipientStatus;
    }

    function getGrantShipRecipient(address _recipientId) public view returns (Recipient memory) {
        Recipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        return grantShipRecipient;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory shipRecipient = getGrantShipRecipient(_recipientId);
        return PayoutSummary(address(shipRecipient.recipientAddress), shipRecipient.grantAmount);
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        // return isGameManager(_allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
