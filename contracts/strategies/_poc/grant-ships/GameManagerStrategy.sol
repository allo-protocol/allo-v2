// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol"; //remove after testing

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IStrategy} from "../../../core/interfaces/IStrategy.sol";

import {IRegistry} from "../../../core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {Allo} from "../../../../contracts/core/Allo.sol";

// SubStrategy Contracts
import {GrantShipStrategy} from "./GrantShipStrategy.sol";

//Internal Libraries
import {ShipInitData} from "./libraries/GrantShipShared.sol";

contract GameManagerStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Models ==============
    /// ================================

    enum ShipStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Active,
        Completed,
        InReview
    }

    struct GameRound {
        uint256 startTime;
        uint256 endTime;
        uint256 totalRoundAmount;
        address roundToken;
        Status roundStatus;
    }

    struct Applicant {
        address applicantId;
        Metadata metadata;
        Status status;
    }

    struct Recipient {
        address recipientId;
        address payable shipAddress;
        address payable previousAddress;
        uint256 shipPoolId;
        uint256 grantAmount;
        Metadata metadata;
        ShipStatus shipStatus;
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
    bool public registryGating;
    uint256 public metadataProtocol;

    address public gameManager;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;
    Allo private _allo;
    IRegistry private _registry;

    // ///@notice This maps the recipientId to the recipient
    // ///@dev 'recipientId' to 'Recipient'
    // mapping(address => Recipient) public grantShipRecipients;

    ///@notice Mapping of all GrantShip Recipients
    ///@dev 'shipAddress' to 'Recipient'
    mapping(address => Recipient) public grantShips;

    //@notice Mapping of all ship applications
    ///@dev 'recipientAddress' to 'Metadata'
    mapping(address => Applicant) public applications;

    ///@notice Array of all Game Rounds
    GameRound[] public gameRounds;

    ///@notice index of the current game round
    uint256 public currentRound;

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
        __gameState_init(_data);
    }

    function __gameState_init(bytes memory _data) internal {
        (
            uint256 _gameFacilitatorId,
            uint256 _metadataProtocol,
            address _hatsAddress,
            address _gameManager,
            bool _registryGating
        ) = abi.decode(_data, (uint256, uint256, address, address, bool));

        gameFacilitatorHatId = _gameFacilitatorId;
        metadataProtocol = _metadataProtocol;
        registryGating = _registryGating;

        gameManager = _gameManager;
        _hats = IHats(_hatsAddress);
        _registry = _allo.getRegistry();
    }

    // function __grantShips_init(bytes[] memory _shipData) internal {
    //     IRegistry registry = _allo.getRegistry();

    //     // registerShip

    //     for (uint256 i = 0; i < _shipData.length;) {
    //         (ShipInitData memory shipInitData) = abi.decode(_shipData[i], (ShipInitData));

    //         // Note:
    //         // Would be nice to have the captain address as a manager
    //         // but owner has to be msg.sender in order to create a manager.
    //         // can always do it in a separate call later.
    //         address[] memory profileManagers = new address[](2);
    //         profileManagers[0] = shipInitData.recipientId;
    //         profileManagers[1] = gameManager;

    //         address[] memory poolAdminAsManager = new address[](1);
    //         poolAdminAsManager[0] = gameManager;

    //         GrantShipStrategy grantShip = new GrantShipStrategy(address(allo), shipInitData.shipName);

    //         bytes32 shipProfileId = registry.createProfile(
    //             i, shipInitData.shipName, shipInitData.shipMetadata, address(this), profileManagers
    //         );

    //         address payable strategyAddress = payable(address(grantShip));

    //         uint256 shipPoolId = _allo.createPoolWithCustomStrategy(
    //             shipProfileId,
    //             strategyAddress,
    //             abi.encode(shipInitData, address(this)),
    //             token,
    //             0,
    //             shipInitData.shipMetadata,
    //             // pool manager/game facilitator role will be mediated through Hats Protocol
    //             // pool_admin address will be the game_facilitator multisig
    //             // using pool_admin as a single address for both roles
    //             poolAdminAsManager
    //         );

    //         Recipient memory newShipRecipient = Recipient(
    //             shipInitData.recipientId,
    //             strategyAddress,
    //             payable(address(0)),
    //             shipPoolId,
    //             0,
    //             shipInitData.shipMetadata,
    //             Status.Pending
    //         );

    //         grantShipRecipients.push(newShipRecipient);

    //         unchecked {
    //             i++;
    //             _shipNonce++;
    //         }
    //     }
    // }

    function approveShips(address[] memory _shipAddresses) external onlyGameFacilitator(msg.sender) {
        // uint256 shipLength = _shipAddresses.length;
        // for (uint256 i = 0; i < shipLength; i++) {
        //     Recipient storage shipRecipient = grantShipRecipients[_shipAddresses[i]];

        //     if (shipRecipient.recipientStatus != Status.Pending) revert INVALID_STATUS();

        //     shipRecipient.recipientStatus = Status.Accepted;
        // }
    }

    function rejectShips(address[] memory _shipAddresses) external onlyGameFacilitator(msg.sender) {
        // uint256 shipLength = _shipAddresses.length;
        // for (uint256 i = 0; i < shipLength; i++) {
        //     Recipient storage shipRecipient = grantShipRecipients[_shipAddresses[i]];

        //     if (shipRecipient.recipientStatus != Status.Pending) revert INVALID_STATUS();

        //     shipRecipient.recipientStatus = Status.Rejected;
        // }
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

    function getHatsAddress() public view returns (address) {
        return address(_hats);
    }

    function isGameFacilitator(address _address) public view returns (bool) {
        return _hats.isWearerOfHat(_address, gameFacilitatorHatId);
    }

    function getShipAddress(uint256 _shipId) public view returns (address payable) {
        // return grantShipRecipients[_shipId].shipAddress;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    function _createGrantShipStrategy(address _strategyImpl, bytes memory _data, uint256 grantShipNumber)
        internal
        returns (address payable)
    {}

    // Register to be a ship. This step does not create a ship, it just registers the address to be a ship.
    // Users can re-register to update their metadata.

    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        returns (address applicantId)
    {
        Metadata memory metadata;
        address registryAnchor;

        if (registryGating) {
            (applicantId, metadata) = abi.decode(_data, (address, Metadata));

            if (!_isProfileMember(applicantId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (registryAnchor, metadata) = abi.decode(_data, (address, Metadata));
            // Check if the registry anchor is valid so we know whether to use it or not
            bool isUsingRegistryAnchor = registryAnchor != address(0);
            // Ternerary to set the recipient id based on whether or not we are using the 'registryAnchor' or '_sender'
            applicantId = isUsingRegistryAnchor ? registryAnchor : _sender;

            if (isUsingRegistryAnchor && !_isProfileMember(applicantId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        // Check to ensure that the metadata protocol is correct
        if (metadata.protocol != metadataProtocol || bytes(metadata.pointer).length == 0) {
            revert INVALID_METADATA();
        }
        // Check if the applicant has not already registered

        Applicant memory applicant = Applicant(applicantId, metadata, Status.Pending);
        applications[applicantId] = applicant;
        emit Registered(applicantId, _data, _sender);
        return applicantId;
    }

    // function _beforeAllocate(bytes memory, address _sender) internal view override {
    //     if (!isGameManager(_sender)) revert UNAUTHORIZED();
    // }

    // function _beforeDistribute(address[] memory, bytes memory, address _sender) internal view override {
    //     if (!isGameManager(_sender)) revert UNAUTHORIZED();
    // }

    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
        // Recipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        // return grantShipRecipient.recipientStatus;
    }

    function getGrantShipRecipient(address _recipientId) public view returns (Recipient memory) {
        // Recipient memory grantShipRecipient = grantShipRecipients[_recipientId];
        // return grantShipRecipient;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory shipRecipient = getGrantShipRecipient(_recipientId);
        return PayoutSummary(address(shipRecipient.shipAddress), shipRecipient.grantAmount);
    }

    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        // return isGameManager(_allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
