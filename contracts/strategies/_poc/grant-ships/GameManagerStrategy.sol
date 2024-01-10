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
        Allocated,
        Funded,
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
        address recipientAddress;
        bytes32 profileId;
        string shipName;
        address payable shipAddress;
        address payable previousAddress;
        uint256 shipPoolId;
        uint256 grantAmount;
        Metadata metadata;
        ShipStatus status;
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
    event ApplicationRejected(address recipientAddress);

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
    uint256 public allocatedAmount;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;
    Allo private _allo;
    IRegistry private _registry;

    // ///@notice This maps the recipientId to the recipient
    // ///@dev 'recipientId' to 'Recipient'
    // mapping(address => Recipient) public grantShipRecipients;

    ///@notice Mapping of all GrantShip Recipients
    ///@dev 'recipientAddress' to 'Recipient'
    mapping(address => Recipient) public recipients;

    //@notice Mapping of all ship applications
    ///@dev 'recipientAddress' to 'Applicant'
    // mapping(address => Applicant) public applications;

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

    function reviewRecipient(address recipientAddress, ShipStatus _approvalFlag, ShipInitData memory shipInitData)
        external
        onlyGameFacilitator(msg.sender)
        returns (address payable)
    {
        Recipient storage recipient = recipients[recipientAddress];
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.roundStatus != RoundStatus.Pending) revert INVALID_STATUS();

        // check if there is a current round. If not, revert

        if (recipient.status != ShipStatus.Pending) revert INVALID_STATUS();
        if (_approvalFlag != ShipStatus.Accepted && _approvalFlag != ShipStatus.Rejected) revert INVALID_STATUS();

        if (_approvalFlag == ShipStatus.Accepted) {
            recipient.status = ShipStatus.Accepted;
            return _createShip(recipient, shipInitData, currentRound);
        } else {
            recipient.status = ShipStatus.Rejected;
            emit ApplicationRejected(recipientAddress);
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

    function _createShip(Recipient memory _recipient, ShipInitData memory _shipInitData, GameRound memory _currentRound)
        internal
        returns (address payable)
    {
        // Deploy a new GrantShipStrategy contract
        GrantShipStrategy grantShip = new GrantShipStrategy(address(allo), _recipient.shipName);

        address payable strategyAddress = payable(address(grantShip));
        address[] memory noManagers = new address[](0);

        // Create a new pool with the GrantShipStrategy contract
        uint256 shipPoolId = _allo.createPoolWithCustomStrategy(
            _recipient.profileId,
            strategyAddress,
            abi.encode(_shipInitData, address(this)),
            _currentRound.token,
            0,
            _recipient.metadata,
            // No Managers: This strategy uses Hats Protocol for permissioning
            // Permissions remain composable and fully revokable by anyone up the Hats Tree
            noManagers
        );

        // Update the recipient with the new poolId

        Recipient storage recipient = recipients[_recipient.recipientAddress];

        recipient.shipPoolId = shipPoolId;
        recipient.shipAddress = strategyAddress;
        recipient.status = ShipStatus.Accepted;

        emit ShipLaunched(
            strategyAddress, shipPoolId, _recipient.recipientAddress, _recipient.shipName, _recipient.metadata
        );

        return strategyAddress;
    }

    function _allocate(bytes memory _data, address _sender) internal virtual override onlyGameFacilitator(_sender) {
        (address[] memory _recipientIds, uint256[] memory _amounts, uint256 _total) =
            abi.decode(_data, (address[], uint256[], uint256));

        bool hasFunds = poolAmount >= _total;

        // checks that pool amount is the same as the total amount
        if (!hasFunds) revert NOT_ENOUGH_FUNDS();

        GameRound storage currentRound = gameRounds[currentRoundIndex];

        // checks that the current round is pending
        if (currentRound.roundStatus != RoundStatus.Pending) revert INVALID_STATUS();

        // checks that the arrays are the same length
        if (_recipientIds.length != _amounts.length) revert ARRAY_MISMATCH();

        uint256 totalAllocated;

        for (uint32 i; _recipientIds.length > 0;) {
            Recipient storage recipient = recipients[_recipientIds[_recipientIds.length - 1]];
            address recipientAddress = _recipientIds[i];
            uint256 grantAmount = _amounts[i];

            // checks that the Recipient status is Accepted
            if (recipient.status != ShipStatus.Accepted) revert INVALID_STATUS();

            // checks that the Recipient is not already allocated
            if (recipient.grantAmount != 0) revert INVALID_STATUS();

            // check that there is enough in the pool
            if (poolAmount < grantAmount + totalAllocated) revert NOT_ENOUGH_FUNDS();

            // adds the grant amount to the total allocated
            totalAllocated += grantAmount;

            // sets the grant amount on the recipient
            recipient.grantAmount = grantAmount;

            // adds the recipient to the current round
            currentRound.ships.push(recipientAddress);

            unchecked {
                i++;
            }
        }

        // checks that the total allocated is the same as the total amount
        if (totalAllocated != _total) revert MISMATCH();

        // assigns the amount to the total round amount
        currentRound.totalRoundAmount = totalAllocated;

        // sets the round status to active
        currentRound.roundStatus = RoundStatus.Active;
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

    function getShipAddress(address _recipientAddress) public view returns (address payable) {
        return getRecipient(_recipientAddress).shipAddress;
    }

    function getRecipient(address _recipientAddress) public view returns (Recipient memory) {
        return recipients[_recipientAddress];
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

        Recipient memory recipient = recipients[_anchorAddress];

        if (recipient.status == ShipStatus.Accepted || recipient.status == ShipStatus.Accepted) revert INVALID_STATUS();

        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchorAddress);

        bool shipExists = recipient.shipAddress != address(0);
        bool previousShipExists = recipient.previousAddress != address(0);

        address payable _shipAddress = shipExists ? recipient.shipAddress : payable(address(0));
        address payable _previousAddress = previousShipExists ? recipient.previousAddress : payable(address(0));

        recipients[_anchorAddress] = Recipient(
            _anchorAddress, profile.id, _shipName, _shipAddress, _previousAddress, 0, 0, _metadata, ShipStatus.Pending
        );

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
        return isGameFacilitator(_allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
