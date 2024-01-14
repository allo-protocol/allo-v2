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

// TODO CLean, reorgnaize, and document this contract
contract GameManagerStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct/Enum =========
    /// ================================

    enum GameStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Allocated,
        Funded,
        Active,
        Completed
    }

    struct GameRound {
        uint256 startTime;
        uint256 endTime;
        uint256 totalRoundAmount;
        GameStatus status;
        address[] ships;
    }

    struct Recipient {
        address recipientAddress;
        bytes32 profileId;
        string shipName;
        address payable shipAddress;
        uint256 shipPoolId;
        uint256 grantAmount;
        Metadata metadata;
        GameStatus status;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when the game status or regular status is invalid.
    error INVALID_STATUS();

    error INVALID_TIME();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event RoundCreated(uint256 gameIndex, uint256 totalRoundAmount);
    event ShipLaunched(
        address shipAddress, uint256 shipPoolId, address applicantId, string shipName, Metadata metadata
    );
    event RecipientRejected(address recipientAddress);

    event GameActive(bool active, uint256 gameIndex);

    event GameManagerInitialized(uint256 gameFacilitatorId, address hatsAddress, address rootAccount, address token);

    event UpdatePosted(string indexed tag, uint256 indexed role, address indexed recipientId, Metadata content);

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    address public rootAccount;

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;

    address public token;

    Allo private _allo;

    IRegistry private _registry;

    ///@notice Mapping of all GrantShip Recipients
    ///@dev 'recipientAddress' to 'Recipient'
    mapping(address => Recipient) public recipients;

    ///@notice Array of all Game Rounds
    GameRound[] public gameRounds;

    ///@notice index of the current game round
    uint256 public currentRoundIndex;

    uint256 public gameFacilitatorHatId;

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
        _setPoolActive(true);
    }

    function __GameManager_init(bytes memory _data) internal {
        (uint256 _gameFacilitatorId, address _hatsAddress, address _rootAccount) =
            abi.decode(_data, (uint256, address, address));

        gameFacilitatorHatId = _gameFacilitatorId;

        rootAccount = _rootAccount;

        _hats = IHats(_hatsAddress);

        _registry = _allo.getRegistry();

        token = allo.getPool(poolId).token;

        emit GameManagerInitialized(_gameFacilitatorId, _hatsAddress, _rootAccount, token);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

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

    function isGameActive() public view returns (bool) {
        return !_isPoolActive();
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    function createRound(uint256 _totalRoundAmount) external onlyGameFacilitator(msg.sender) returns (uint256) {
        // Note: This check allows us to create the first round, then checks the previous round for
        // the correct status. Doesn't seem like the cleanest way to do this, open to suggestions.
        if (gameRounds.length > 0 && gameRounds[gameRounds.length - 1].status != GameStatus.Completed) {
            revert INVALID_STATUS();
        }

        GameRound memory round = GameRound(0, 0, _totalRoundAmount, GameStatus.Pending, new address[](0));

        gameRounds.push(round);

        emit RoundCreated(currentRoundIndex, _totalRoundAmount);
        return currentRoundIndex;
    }

    function reviewRecipient(address recipientAddress, GameStatus _approvalFlag, ShipInitData memory shipInitData)
        external
        onlyGameFacilitator(msg.sender)
        returns (address payable)
    {
        Recipient storage recipient = recipients[recipientAddress];
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.status != GameStatus.Pending) revert INVALID_STATUS();

        // check if there is a current round. If not, revert

        if (recipient.status != GameStatus.Pending) revert INVALID_STATUS();
        if (_approvalFlag != GameStatus.Accepted && _approvalFlag != GameStatus.Rejected) revert INVALID_STATUS();

        if (_approvalFlag == GameStatus.Accepted) {
            recipient.status = GameStatus.Accepted;
            return _createShip(recipient, shipInitData);
        } else {
            recipient.status = GameStatus.Rejected;
            emit RecipientRejected(recipientAddress);
            return payable(address(0));
        }
    }

    function startGame() external onlyGameFacilitator(msg.sender) onlyActivePool {
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.status != GameStatus.Funded) revert INVALID_STATUS();
        if (block.timestamp < currentRound.startTime) revert INVALID_TIME();

        currentRound.status = GameStatus.Active;
        _setPoolActive(false);

        emit GameActive(true, currentRoundIndex);
    }

    function stopGame() external onlyGameFacilitator(msg.sender) onlyInactivePool {
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.status != GameStatus.Active) revert INVALID_STATUS();
        if (block.timestamp < currentRound.endTime) revert INVALID_TIME();

        for (uint256 i; i < currentRound.ships.length;) {
            Recipient storage recipient = recipients[currentRound.ships[i]];
            recipient.status = GameStatus.Completed;
            unchecked {
                i++;
            }
        }

        currentRound.status = GameStatus.Completed;
        _setPoolActive(true);
        currentRoundIndex++;

        emit GameActive(false, currentRoundIndex);
    }

    function withdraw(uint256 _amount) external {
        if (_amount > poolAmount) revert NOT_ENOUGH_FUNDS();
        if (msg.sender != rootAccount && !isGameFacilitator(msg.sender)) revert UNAUTHORIZED();

        poolAmount -= _amount;

        _transferAmount(token, rootAccount, _amount);
    }

    function postUpdate(string memory _tag, Metadata memory _content) external {
        if (isGameFacilitator(msg.sender)) {
            emit UpdatePosted(_tag, gameFacilitatorHatId, address(0), _content);
        } else if (msg.sender == rootAccount) {
            emit UpdatePosted(_tag, 0, rootAccount, _content);
        } else {
            revert UNAUTHORIZED();
        }
    }

    function _createShip(Recipient memory _recipient, ShipInitData memory _shipInitData)
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
            token,
            0,
            _recipient.metadata,
            // No Managers: This strategy uses Hats Protocol for permissioning
            // Permissions remain composable and fully revokable by anyone up the Hats Tree
            noManagers
        );

        Recipient storage recipient = recipients[_recipient.recipientAddress];

        recipient.shipPoolId = shipPoolId;
        recipient.shipAddress = strategyAddress;
        recipient.status = GameStatus.Accepted;

        emit ShipLaunched(
            strategyAddress, shipPoolId, _recipient.recipientAddress, _recipient.shipName, _recipient.metadata
        );

        return strategyAddress;
    }

    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyGameFacilitator(_sender)
        nonReentrant
    {
        (address[] memory _recipientIds, uint256[] memory _amounts, uint256 _total) =
            abi.decode(_data, (address[], uint256[], uint256));
        // Ensure funds have been added to the pool
        if (poolAmount < _total) revert NOT_ENOUGH_FUNDS();
        // Prevent overflow errors
        if (gameRounds.length == 0) revert ARRAY_MISMATCH();
        GameRound storage currentRound = gameRounds[currentRoundIndex];
        // checks that the current round is pending
        if (currentRound.status != GameStatus.Pending) revert INVALID_STATUS();

        // checks that the arrays are the same length
        if (_recipientIds.length != _amounts.length) revert ARRAY_MISMATCH();

        uint256 totalAllocated;

        for (uint256 i; i < _recipientIds.length;) {
            Recipient storage recipient = recipients[_recipientIds[i]];
            // checks that the Recipient status is Accepted
            if (recipient.status != GameStatus.Accepted) revert INVALID_STATUS();

            address recipientAddress = _recipientIds[i];
            uint256 allocation = _amounts[i];

            // check that there is enough in the pool
            if (poolAmount < allocation + totalAllocated) revert NOT_ENOUGH_FUNDS();
            // adds the grant amount to the total allocated
            totalAllocated += allocation;
            // sets the grant amount on the recipient
            recipient.grantAmount = allocation;
            // adds the recipient to the current round
            currentRound.ships.push(recipientAddress);
            // sets the recipient status to Allocated
            recipient.status = GameStatus.Allocated;

            emit Allocated(recipientAddress, allocation, token, _sender);

            unchecked {
                i++;
            }
        }

        // checks that the total allocated is the same as the total amount
        if (totalAllocated != _total) revert MISMATCH();
        // assigns the amount to the round round amount
        currentRound.totalRoundAmount = totalAllocated;
        // sets the round status to active
        currentRound.status = GameStatus.Allocated;
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyGameFacilitator(_sender)
    {
        // Prevent overflow errors, ensure arrays are the same length
        if (_recipientIds.length != gameRounds[currentRoundIndex].ships.length) {
            revert ARRAY_MISMATCH();
        }

        GameRound storage currentRound = gameRounds[currentRoundIndex];
        // Ensure funds have been added to the pool
        if (poolAmount < currentRound.totalRoundAmount) revert NOT_ENOUGH_FUNDS();
        // checks that the current round is allocated
        if (currentRound.status != GameStatus.Allocated) revert INVALID_STATUS();

        for (uint256 i; i < _recipientIds.length;) {
            Recipient storage recipient = recipients[_recipientIds[i]];
            // checks that the Recipient status is Allocated
            if (recipient.status != GameStatus.Allocated) revert INVALID_STATUS();

            poolAmount -= recipient.grantAmount;

            recipient.status = GameStatus.Active;

            GrantShipStrategy grantShip = GrantShipStrategy(recipient.shipAddress);

            // Note: I need a way to increase the pool amount on the child strategies
            // Calling fundPool on the child strategy does not work here because it triggers the
            // re-entrancy guard on Allo. I solve this problem by transferring the funds directly
            // and then calling the managerIncreasePoolAmount function on the child strategy.

            grantShip.managerIncreasePoolAmount(recipient.grantAmount);
            _transferAmount(token, recipient.shipAddress, recipient.grantAmount);

            unchecked {
                i++;
            }
            emit Distributed(recipient.recipientAddress, recipient.shipAddress, recipient.grantAmount, _sender);
        }

        (uint256 startTime, uint256 endTime) = abi.decode(_data, (uint256, uint256));

        currentRound.startTime = startTime;
        currentRound.endTime = endTime;
        currentRound.status = GameStatus.Funded;
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
        if (bytes(_metadata.pointer).length == 0) {
            revert INVALID_METADATA();
        }

        Recipient memory recipient = recipients[_anchorAddress];

        // Todo check what other statuses should be guarded against here

        GameStatus recipientStatus = recipient.status;
        if (
            recipientStatus != GameStatus.None && recipientStatus != GameStatus.Completed
                && recipientStatus != GameStatus.Rejected && recipientStatus != GameStatus.Pending
        ) revert INVALID_STATUS();

        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchorAddress);

        recipients[_anchorAddress] =
            Recipient(_anchorAddress, profile.id, _shipName, payable(address(0)), 0, 0, _metadata, GameStatus.Pending);

        emit Registered(_anchorAddress, _data, _sender);
        return _anchorAddress;
    }

    function _getRecipientStatus(address) internal view virtual override returns (Status) {
        // Note: We would like to return GameStatus here, but it is not possible to return a GameStatus
        // with the override
        return Status.None;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        // TODO: This is status dependant, we should return exactly how much the ship has been paid.

        Recipient memory shipRecipient = getRecipient(_recipientId);
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
