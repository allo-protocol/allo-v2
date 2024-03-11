// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// import "forge-std/Test.sol";

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Interfaces
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";

import {IRegistry} from "../../../core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "../../BaseStrategy.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";

// SubStrategy Contracts
import {GrantShipStrategy} from "./GrantShipStrategy.sol";

//Internal Libraries
import {ShipInitData} from "./libraries/GrantShipShared.sol";
import {GrantShipFactory} from "./libraries/GrantShipFactory.sol";

/// @title RFP Simple Strategy
/// @author @Jord
/// @notice Strategy for allocation to GrantShips and managing the Grant Ships lifecycle.
contract GameManagerStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct/Enum =========
    /// ================================

    /// @notice Custom Status for managing the lifecycle GrantShips
    /// Todo - This should be a Status enum from overwrite
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

    /// @notice Struct holding the data for each round of the game
    struct GameRound {
        uint256 startTime;
        uint256 endTime;
        uint256 totalRoundAmount;
        GameStatus status;
        address[] ships;
    }

    /// @notice Struct holding the data for each GrantShip recipient
    struct Recipient {
        address recipientAddress;
        bytes32 profileId;
        string shipName;
        address payable shipAddress;
        uint256 shipPoolId;
        uint256 grantAmount;
        uint256 totalAmountRecieved;
        Metadata metadata;
        GameStatus status;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when the game status or GrantShip recipient status is invalid.
    error INVALID_STATUS();

    /// @notice Throws when a function is being called at an invalid time.
    error INVALID_TIME();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a new round of the game is created.
    /// @param gameIndex The index of the game round.
    /// @param totalRoundAmount The total funding amount of the round.
    event RoundCreated(uint256 gameIndex, uint256 totalRoundAmount);

    /// @notice Emitted when a new GrantShip recipient is Accepted and their Ship Strategy is deployed.
    /// @param shipAddress The deployed contract address of the GrantShip Strategy.
    /// @param shipPoolId The Allo Pool Id for the GrantShip Strategy.
    /// @param recipientId The address of the GrantShip recipient. This will the Ship or team's anchor address
    /// @param shipName The name of the GrantShip.
    /// @param metadata The metadata of the GrantShip.
    event ShipLaunched(
        address shipAddress, uint256 shipPoolId, address recipientId, string shipName, Metadata metadata
    );

    /// @notice Emitted when a new GrantShip recipient is Rejected.
    /// @param recipientAddress The anchor address of the GrantShip recipient.
    /// @param reason The reason for the rejection.
    event RecipientRejected(address recipientAddress, Metadata reason);

    /// @notice Emitted when a new GrantShip recipient is Rejected.
    /// @param recipientAddress The anchor address of the GrantShip recipient.
    /// @param reason The reason for the rejection.
    event RecipientAccepted(address recipientAddress, Metadata reason);

    /// @notice Emitted when a new GrantShip recipient is Registered.
    /// @param active boolean indicating whether or the GrantShips Round is active.
    /// @param gameIndex The index of the game round.
    event GameActive(bool active, uint256 gameIndex);

    /// @notice Emitted when the GameManager is initialized.
    /// @param gameFacilitatorId The Hats Protocol Id for the Game Facilitator.
    /// @param hatsAddress The address of the Hats Protocol contract.
    /// @param rootAccount The address of the root account.
    /// @param token The address of the token used for funding GrantShips.
    event GameManagerInitialized(
        uint256 gameFacilitatorId, address hatsAddress, address rootAccount, address token, uint256 poolId
    );

    /// @notice Emitted when a content update is posted. Permissioned to facilitators or root account.
    event UpdatePosted(string indexed tag, uint256 indexed role, address indexed recipientId, Metadata content);

    /// @notice Emitted after distribtion of funds to GrantShip recipients. Tracks Game round times.
    event GameRoundTimesCreated(uint256 indexed gameRoundIndex, uint256 startTime, uint256 endTime);

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice The 'Hats Protocol' contract interface.
    IHats private _hats;

    /// @notice The Allo Registry contract interface
    IRegistry private _registry;

    /// @notice The address of the root account. This is the account that funds are withdrawn to.
    address public rootAccount;

    /// @notice The address of the token used for funding GrantShips.
    address public token;

    ///@notice Mapping of all GrantShip Recipients
    ///@dev 'recipientAddress' to 'Recipient'
    mapping(address => Recipient) public recipients;

    ///@notice Array of all Game Rounds.
    GameRound[] public gameRounds;

    ///@notice index of the current game round
    uint256 public currentRoundIndex;

    /// @notice The Hats Protocol Id for managing the lifecycle of GrantShips.
    uint256 public gameFacilitatorHatId;

    /// ===============================
    /// ========== Modifiers ==========
    /// ===============================

    /// @notice Modifier to restrict functions to the Game Facilitator.
    modifier onlyGameFacilitator(address _sender) {
        if (!_hats.isWearerOfHat(_sender, gameFacilitatorHatId)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the GameManager Strategy
    /// @param _alloAddress The 'Allo' contract address
    /// @param _name The name of the strategy
    constructor(address _alloAddress, string memory _name) BaseStrategy(_alloAddress, _name) {}

    /// ===============================
    /// ======== Initialize ===========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (uint256 gameFacilitatorId, address hatsAddress, address rootAccount)
    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);
        __GameManager_init(_data);
        _setPoolActive(true);
    }

    /// @notice This initializes the BaseStrategy and parameters specific to the GameManager Strategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _data The data to be decoded
    /// @custom:data (uint256 gameFacilitatorId, address hatsAddress, address rootAccount)
    /// @dev registryGating, metadataRequired, grantAmountRequired are all implicitly set to true
    function __GameManager_init(bytes memory _data) internal {
        (uint256 _gameFacilitatorId, address _hatsAddress, address _rootAccount) =
            abi.decode(_data, (uint256, address, address));

        gameFacilitatorHatId = _gameFacilitatorId;

        rootAccount = _rootAccount;

        _hats = IHats(_hatsAddress);

        _registry = allo.getRegistry();

        token = allo.getPool(poolId).token;

        emit GameManagerInitialized(_gameFacilitatorId, _hatsAddress, _rootAccount, token, poolId);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientAddress The address of the recipient
    /// @return returns the recipient struct
    function getRecipient(address _recipientAddress) public view returns (Recipient memory) {
        return recipients[_recipientAddress];
    }

    /// @notice Get the ship contract address
    /// @param _recipientAddress The address of the recipient
    /// @return returns the ship contract address
    function getShipAddress(address _recipientAddress) public view returns (address payable) {
        return getRecipient(_recipientAddress).shipAddress;
    }

    /// @notice Get the game round
    /// @param _gameRoundIndex The index of the game round you wish to return
    /// @return returns the GameRound struct
    function getGameRound(uint256 _gameRoundIndex) public view returns (GameRound memory) {
        return gameRounds[_gameRoundIndex];
    }

    /// @notice Getter to test if an address is the Game Facilitator
    /// @param _address The address you wish to test
    function isGameFacilitator(address _address) public view returns (bool) {
        return _hats.isWearerOfHat(_address, gameFacilitatorHatId);
    }

    /// @notice Get the deployment address of Hats Protocol
    /// @return returns the address of the Hats Protocol contract
    function getHatsAddress() public view returns (address) {
        return address(_hats);
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Game Facilitators create a new round of the game
    /// @param _totalRoundAmount The total funding amount of the round.
    /// @return returns the index of the new game round
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

    /// @notice Game Facilitators review GrantShip applicants and create a new GrantShip Strategy
    /// @param _recipientAddress The address of the GrantShip applicant
    /// @param _approvalFlag The approval status of the GrantShip applicant (Accepted/Rejected)
    /// @param _shipInitData The init data for the GrantShip Strategy (see GrantShipShared for struct)
    /// @param _reason The reason for the approval or rejection
    function reviewRecipient(
        address _recipientAddress,
        GameStatus _approvalFlag,
        ShipInitData memory _shipInitData,
        address _shipFactoryAddress,
        Metadata memory _reason
    ) external onlyGameFacilitator(msg.sender) returns (address payable) {
        Recipient storage recipient = recipients[_recipientAddress];

        // If we haven't created a round, revert
        if (gameRounds.length == 0) revert ARRAY_MISMATCH();

        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.status != GameStatus.Pending) revert INVALID_STATUS();

        // check if there is a current round. If not, revert

        if (recipient.status != GameStatus.Pending) revert INVALID_STATUS();
        if (_approvalFlag != GameStatus.Accepted && _approvalFlag != GameStatus.Rejected) revert INVALID_STATUS();

        if (_approvalFlag == GameStatus.Accepted) {
            recipient.status = GameStatus.Accepted;
            emit RecipientAccepted(_recipientAddress, _reason);
            return _createShip(recipient, _shipInitData, _shipFactoryAddress);
        } else {
            recipient.status = GameStatus.Rejected;
            emit RecipientRejected(_recipientAddress, _reason);
            return payable(address(0));
        }
    }

    /// @notice Game Facilitators start the game
    /// @dev This function will set the pool to inactive and start the game.
    /// This happens after registrations, review, allocation, and distribution have been completed.
    /// 'Game Start' activates the GrantShip strategies deployed by this contract.
    function startGame() external onlyGameFacilitator(msg.sender) onlyActivePool {
        GameRound storage currentRound = gameRounds[currentRoundIndex];

        if (currentRound.status != GameStatus.Funded) revert INVALID_STATUS();
        if (block.timestamp < currentRound.startTime) revert INVALID_TIME();

        currentRound.status = GameStatus.Active;
        _setPoolActive(false);

        emit GameActive(true, currentRoundIndex);
    }

    /// @notice Game Facilitators stop the game
    /// @dev This function will set the pool to active and stop the game.
    /// This happens after the game has been started and the end time has been reached.
    /// 'Game Start' deactivates the GrantShip strategies deployed by this contract and increments the round counter.
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

    /// @notice Game Facilitators withdraw funds from the pool
    /// @param _amount The amount to withdraw
    /// @dev This function will withdraw funds from the pool and transfer them to the root account only.
    function withdraw(uint256 _amount) external {
        if (_amount > poolAmount) revert NOT_ENOUGH_FUNDS();
        if (msg.sender != rootAccount && !isGameFacilitator(msg.sender)) revert UNAUTHORIZED();

        poolAmount -= _amount;

        _transferAmount(token, rootAccount, _amount);
    }

    function setPoolActive(bool _flag) external onlyGameFacilitator(msg.sender) {
        _setPoolActive(_flag);
        emit PoolActive(_flag);
    }

    /// @notice Game Facilitators or root account post updates about the GrantShips
    /// @param _tag The tag of the update, used to mark the type of update when indexing
    /// @param _content The content of the update,
    function postUpdate(string memory _tag, Metadata memory _content) external {
        if (isGameFacilitator(msg.sender)) {
            emit UpdatePosted(_tag, gameFacilitatorHatId, address(0), _content);
        } else if (msg.sender == rootAccount) {
            emit UpdatePosted(_tag, 0, rootAccount, _content);
        } else {
            revert UNAUTHORIZED();
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Called by reviewRecipient, this function deploys a new GrantShip Strategy
    /// @param _recipient The recipient struct
    /// @param _shipInitData The init data for the GrantShip Strategy (see GrantShipShared for struct)
    function _createShip(Recipient memory _recipient, ShipInitData memory _shipInitData, address _shipFactoryAddress)
        internal
        returns (address payable)
    {
        // Deploy a new GrantShipStrategy contract
        address strategyAddress = GrantShipFactory(_shipFactoryAddress).create(_recipient.recipientAddress);

        address[] memory noManagers = new address[](0);

        bytes32 contractProfileId = _createShipProfile(_recipient.recipientAddress, currentRoundIndex, _shipInitData);

        // Create a new pool with the GrantShipStrategy contract
        uint256 shipPoolId = allo.createPoolWithCustomStrategy(
            contractProfileId,
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
        recipient.shipAddress = payable(strategyAddress);
        recipient.status = GameStatus.Accepted;

        emit ShipLaunched(
            strategyAddress, shipPoolId, _recipient.recipientAddress, _recipient.shipName, _recipient.metadata
        );

        return payable(strategyAddress);
    }

    /// @notice Allocates funds to Accepted GrantShip recipients who are in the upcoming round
    /// @param _data The data to be decoded
    /// @custom:data (address[] _recipientIds, uint256[] _amounts, uint256 _total)
    /// @dev This function is called by the Allocator and is permissioned to the Game Facilitator
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

    /// @notice Distributes funds to GrantShip recipients who are in the current round
    /// @param _data The data to be decoded
    /// @custom:data (address[] _recipientIds, uint256[] _amounts, uint256 _total)
    /// @dev This function is called by the Allocator and is permissioned to the Game Facilitator
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
            // CHECK that the Recipient status is Allocated
            if (recipient.status != GameStatus.Allocated) revert INVALID_STATUS();

            /// EFFECTS:
            poolAmount -= recipient.grantAmount;
            recipient.totalAmountRecieved += recipient.grantAmount;
            recipient.status = GameStatus.Active;

            GrantShipStrategy grantShip = GrantShipStrategy(recipient.shipAddress);

            // Review: I need a way to increase the pool amount on the child strategies
            // Calling fundPool on the child strategy does not work here because it triggers the
            // re-entrancy guard on Allo. I solve this problem by transferring the funds directly
            // and then calling the managerIncreasePoolAmount function on the child strategy.

            /// INTERACTIONS:
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

        emit GameRoundTimesCreated(currentRoundIndex, startTime, endTime);
    }

    /// @notice Registers a new GrantShip recipient
    /// @param _data The data to be decoded
    /// @custom:data (address _anchorAddress, string _shipName, Metadata _metadata)
    /// @param _sender The address of the sender
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

        GameStatus recipientStatus = recipient.status;
        if (
            recipientStatus != GameStatus.None && recipientStatus != GameStatus.Completed
                && recipientStatus != GameStatus.Rejected && recipientStatus != GameStatus.Pending
        ) revert INVALID_STATUS();

        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchorAddress);

        uint256 _totalAmountRecieved = recipients[_anchorAddress].totalAmountRecieved;

        recipients[_anchorAddress] = Recipient(
            _anchorAddress,
            profile.id,
            _shipName,
            payable(address(0)),
            0,
            0,
            _totalAmountRecieved,
            _metadata,
            GameStatus.Pending
        );

        emit Registered(_anchorAddress, _data, _sender);
        return _anchorAddress;
    }

    function _createShipProfile(address _recipientId, uint256 _roundId, ShipInitData memory _shipInitData)
        internal
        returns (bytes32)
    {
        bytes memory encoded = abi.encodePacked(_recipientId, _roundId);
        bytes32 hash = keccak256(encoded);
        uint256 nonce = uint256(hash);

        address[] memory noManagers = new address[](0);

        bytes32 contractProfileId = _registry.createProfile(
            nonce, _shipInitData.shipName, _shipInitData.shipMetadata, address(this), noManagers
        );

        return contractProfileId;
    }

    /// @notice Returns the status of the recipient
    /// @dev currently out of order, until I know the Allo protocol use for this function and how best to adapt to it.
    function _getRecipientStatus(address) internal view virtual override returns (Status) {
        // Note: Not possible to return the status as Recipients use GameStatus

        // Also, overwriting this function Status with GameStatus is not possible, as
        // this violates the function signature of the virtual function in the BaseStrategy contract.

        return Status.None;
    }

    /// @notice Returns the payout summary for the recipient
    /// @param _recipientId The address of the recipient
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory shipRecipient = getRecipient(_recipientId);
        return PayoutSummary(address(shipRecipient.shipAddress), shipRecipient.totalAmountRecieved);
    }

    /// @notice Tests if the sender is a member of the profile
    /// @param _anchor The address of the profile anchor
    /// @param _sender The address of the sender
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Tests if the sender is a valid allocator
    /// @param _allocator The address that is being tested
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return isGameFacilitator(_allocator);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
