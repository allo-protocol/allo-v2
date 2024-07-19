// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// External Libraries
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Core Contracts
import {CoreBaseStrategy} from "../strategies/CoreBaseStrategy.sol";
import {IGatingExtension} from "../core/interfaces/IGatingExtension.sol";

/// @title GatingExtension
/// @notice This contract is providing gating options for a strategy's calls
/// @dev This contract is inheriting CoreBaseStrategy
abstract contract GatingExtension is CoreBaseStrategy, IGatingExtension {
    /// ================================
    /// ========== Storage =============
    /// ================================
    /// @notice The EAS contract
    address public eas;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor
    /// @param _allo The 'Allo' contract
    constructor(address _allo) CoreBaseStrategy(_allo) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (address eas)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        GatingExtensionInitializeParams memory initializeParams = abi.decode(_data, (GatingExtensionInitializeParams));
        __GatingExtension_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the strategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _initializeParams The initialize params
    function __GatingExtension_init(uint256 _poolId, GatingExtensionInitializeParams memory _initializeParams)
        internal
    {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        /// Set the EAS contract
        eas = _initializeParams.eas;
    }

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// @notice This modifier checks if the actor hold a certain amount of tokens
    /// @param _token The token address
    /// @param _amount The amount of tokens
    /// @param _actor The actor address
    modifier onlyWithToken(address _token, uint256 _amount, address _actor) {
        _checkOnlyWithToken(_token, _amount, _actor);
        _;
    }

    /// @notice This modifier checks if the actor holds a certain NFT
    /// @param _nft The NFT address
    /// @param _actor The actor address
    modifier onlyWithNFT(address _nft, address _actor) {
        _checkOnlyWithNFT(_nft, _actor);
        _;
    }

    /// @notice This modifier checks if the sender attest to a schema
    /// @param _schema The unique identifier of the schema
    /// @param _attester The attester address
    /// @param _uid The unique identifier of the attestation
    modifier onlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid) {
        _checkOnlyWithAttestation(_schema, _attester, _uid);
        _;
    }

    /// ===============================
    /// ======= Internal Functions ====
    /// ===============================

    /// @notice This function checks if the actor has a certain amount of tokens
    /// @param _token The token address
    /// @param _amount The amount of tokens
    /// @param _actor The actor address
    function _checkOnlyWithToken(address _token, uint256 _amount, address _actor) internal view {
        if (_token == address(0)) revert GatingExtension_INVALID_TOKEN();
        if (_actor == address(0)) revert GatingExtension_INVALID_ACTOR();
        if (IERC20(_token).balanceOf(_actor) < _amount) revert GatingExtension_INSUFFICIENT_BALANCE();
    }

    /// @notice This function checks if the actor has a certain NFT
    /// @param _nft The NFT address
    /// @param _actor The actor address
    function _checkOnlyWithNFT(address _nft, address _actor) internal view {
        if (_nft == address(0)) revert GatingExtension_INVALID_TOKEN();
        if (_actor == address(0)) revert GatingExtension_INVALID_ACTOR();
        if (IERC721(_nft).balanceOf(_actor) == 0) revert GatingExtension_INSUFFICIENT_BALANCE();
    }

    /// @notice This function checks if the sender has attested to a schema
    /// @param _schema The unique identifier of the schema
    /// @param _attester The attester address
    /// @param _uid The unique identifier of the attestation
    function _checkOnlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid) internal view {
        Attestation memory _attestation = IEAS(eas).getAttestation(_uid);
        if (_attestation.schema != _schema) revert GatingExtension_INVALID_ATTESTATION_SCHEMA();
        if (_attestation.attester != _attester) revert GatingExtension_INVALID_ATTESTATION_ATTESTER();
    }
}
