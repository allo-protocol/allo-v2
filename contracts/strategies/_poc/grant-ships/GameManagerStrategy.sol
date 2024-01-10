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

    enum RoundStatus {
        None,
        Pending,
        Active,
        Completed
    }

    struct GameRound {
        uint256 startTime;
        uint256 endTime;
        uint256 totalRoundAmount;
        address token;
        RoundStatus roundStatus;
        address[] ships;
    }

    struct Applicant {
        address applicantId;
        bytes32 profileId;
        string shipName;
        Metadata metadata;
        Status status;
    }

    struct Recipient {
        address applicantAddress;
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
    error INVALID_TIME();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event RoundCreated(uint256 gameIndex, address token, uint256 totalRoundAmount);
    event ShipLaunched(
        address shipAddress, uint256 shipPoolId, address applicantId, string shipName, Metadata metadata
    );
    event ApplicationRejected(address applicantAddress);

    /// ===============================
    /// ========== Modifiers ==========
    /// ===============================

    modifier onlyGameFacilitator(address _sender) {
        if (!_hats.isWearerOfHat(_sender, gameFacilitatorHatId)) {
            revert UNAUTHORIZED();
        }
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
    ///@dev 'applicantAddress' to 'Recipient'
    mapping(address => Recipient) public grantShips;

    //@notice Mapping of all ship applications
    ///@dev 'applicantAddress' to 'Applicant'
    mapping(address => Applicant) public applications;

    ///@notice Array of all Game Rounds
    GameRound[] public gameRounds;

    ///@notice index of the current game round
    uint256 public currentRoundIndex;

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
        __GameManager_init(_data);
    }

    function __GameManager_init(bytes memory _data) internal {
        (
            uint256 _gameFacilitatorId,
            uint256 _metadataProtocol,
            address _hatsAddress,
            address _gameManager,
            bool _registryGating
        ) = abi.decode(_data, (uint256, uint256, address, address, bool));

        gameFacilitatorHatId = _gameFacilitatorId;
        metadataProtocol = _metadataProtocol;
        // Todo: Remove this
        registryGating = true;

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

    //         bytes32 shipProfileId = registry.createProfile(
    //             i, shipInitData.shipName, shipInitData.shipMetadata, address(this), profileManagers
    //         );

    //         address payable strategyAddress = payable(address(grantShip));

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

    function reviewApplicant(address _applicantAddress, Status _approvalFlag, ShipInitData memory shipInitData)
        external
        onlyGameFacilitator(msg.sender)
        returns (address payable)
    {
        Applicant storage applicant = applications[_applicantAddress];
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.roundStatus != RoundStatus.Pending) revert INVALID_STATUS();

        // check if there is a current round. If not, revert

        if (applicant.status != Status.Pending) revert INVALID_STATUS();
        if (_approvalFlag != Status.Accepted && _approvalFlag != Status.Rejected) revert INVALID_STATUS();

        if (_approvalFlag == Status.Accepted) {
            applicant.status = Status.Accepted;
            return _createShip(applicant, shipInitData, currentRound);
        } else {
            applicant.status = Status.Rejected;
            emit ApplicationRejected(_applicantAddress);
            return payable(address(0));
        }
    }

    function createRound(uint256 _totalRoundAmount, address _tokenAddress)
        external
        onlyGameFacilitator(msg.sender)
        returns (uint256)
    {
        if (gameRounds.length > 0 && gameRounds[currentRoundIndex].roundStatus != RoundStatus.None) {
            revert INVALID_STATUS();
        }

        GameRound memory round =
            GameRound(0, 0, _totalRoundAmount, _tokenAddress, RoundStatus.Pending, new address[](0));

        gameRounds.push(round);

        emit RoundCreated(currentRoundIndex, _tokenAddress, _totalRoundAmount);
        return currentRoundIndex;
    }

    function _createShip(Applicant memory _applicant, ShipInitData memory _shipInitData, GameRound memory _currentRound)
        internal
        returns (address payable)
    {
        // Deploy a new GrantShipStrategy contract
        GrantShipStrategy grantShip = new GrantShipStrategy(address(allo), _applicant.shipName);

        address payable strategyAddress = payable(address(grantShip));
        address[] memory noManagers = new address[](0);

        // Create a new pool with the GrantShipStrategy contract
        uint256 shipPoolId = _allo.createPoolWithCustomStrategy(
            _applicant.profileId,
            strategyAddress,
            abi.encode(_shipInitData, address(this)),
            _currentRound.token,
            0,
            _applicant.metadata,
            // No Managers: This strategy uses Hats Protocol for permissioning
            // Permissions remain composable and fully revokable by anyone up the Hats Tree
            noManagers
        );

        Recipient memory newShipRecipient = Recipient(
            _applicant.applicantId,
            strategyAddress,
            payable(address(0)),
            shipPoolId,
            0,
            _applicant.metadata,
            ShipStatus.Pending
        );

        grantShips[_applicant.applicantId] = newShipRecipient;

        emit ShipLaunched(strategyAddress, shipPoolId, _applicant.applicantId, _applicant.shipName, _applicant.metadata);

        return strategyAddress;
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

    function getApplicant(address _applicantAddress) public view returns (Applicant memory) {
        return applications[_applicantAddress];
    }

    function getShipAddress(address _applicantAddress) public view returns (address payable) {
        return getRecipient(_applicantAddress).shipAddress;
    }

    function getRecipient(address _applicantAddress) public view returns (Recipient memory) {
        return grantShips[_applicantAddress];
    }

    function getHatsAddress() public view returns (address) {
        return address(_hats);
    }

    function getGameRound(uint256 _gameRoundIndex) public view returns (GameRound memory) {
        return gameRounds[_gameRoundIndex];
    }

    function isGameFacilitator(address _address) public view returns (bool) {
        return _hats.isWearerOfHat(_address, gameFacilitatorHatId);
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
    // All Ship Applicants MUST have registered profiles
    function _registerRecipient(bytes memory _data, address _sender) internal virtual override returns (address) {
        (address _anchorAddress, string memory _shipName, Metadata memory _metadata) =
            abi.decode(_data, (address, string, Metadata));

        // Check to ensure that the caller is a member of the profile
        if (!_isProfileMember(_anchorAddress, _sender)) {
            revert UNAUTHORIZED();
        }

        // Check to ensure that the _metadata protocol is correct
        if (_metadata.protocol != metadataProtocol || bytes(_metadata.pointer).length == 0) {
            revert INVALID_METADATA();
        }

        Applicant memory applicant = applications[_anchorAddress];

        if (applicant.status == Status.Accepted) revert INVALID_STATUS();

        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchorAddress);
        applications[_anchorAddress] = Applicant(_anchorAddress, profile.id, _shipName, _metadata, Status.Pending);

        emit Registered(_anchorAddress, _data, _sender);
        return _anchorAddress;
    }

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
