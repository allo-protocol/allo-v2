// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    RevocationRequest,
    RevocationRequestData
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {
    ISchemaRegistry,
    ISchemaResolver,
    SchemaRecord
} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";
// Core Contracts
import {SchemaResolver} from "./SchemaResolver.sol";
import {QVBaseStrategy} from "../qv-base/QVBaseStrategy.sol";

// Register the schema with the SchemaRegistry contract when required.
// https://optimism-goerli.easscan.org/schema/create
// https://docs.attest.sh/docs/tutorials/create-a-schema
// https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/

contract HackathonQVStrategy is QVBaseStrategy, SchemaResolver {
    struct EASInfo {
        IEAS eas;
        ISchemaRegistry schemaRegistry;
        bytes32 schemaUID;
        string schema;
        bool revocable;
    }

    struct TmpRecipient {
        uint256 voteRank;
        address recipientId;
        uint256 foundRecipientAtIndex;
    }

    /// ======================
    /// ==== Custom Error ====
    /// ======================

    error ALREADY_ADDED();
    error OUT_OF_BOUNDS();
    error INVALID_SCHEMA();
    error ALLOCATION_STARTED();

    /// ======================
    /// ====== Storage =======
    /// ======================

    bytes32 constant _NO_RELATED_ATTESTATION_UID = 0;
    ISchemaRegistry public schemaRegistry;
    uint256[] public payoutPercentages;
    uint256[] public votesByRank;
    EASInfo public easInfo;
    ERC721 public nft;

    uint256 public maxVoiceCreditsPerAllocator;

    // recipientId -> uid
    mapping(address => bytes32) public recipientIdToUID;
    // nftId -> voiceCreditsUsed
    mapping(uint256 => uint256) public voiceCreditsUsedPerNftId;
    // recipientId => winner list index
    mapping(address => uint256) public recipientIdToIndex;
    // Winner list index => recipientId
    mapping(uint256 => address) public indexToRecipientId;

    /// ======================
    /// ===== Modifiers ======
    /// ======================

    modifier onlyBeforeAllocation() {
        if (block.timestamp > allocationStartTime) {
            revert ALLOCATION_STARTED();
        }
        _;
    }

    /// ======================
    /// ===== Constructor ====
    /// ======================

    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ======================
    /// ====== Initialize ====
    /// ======================

    /// @dev Initializes the strategy
    /// @param _poolId The pool ID for this strategy
    /// @param _data The data to initialize the strategy with
    function initialize(uint256 _poolId, bytes memory _data) public override onlyAllo {
        (EASInfo memory _easInfo, address _nft, bytes memory _qvSimpleInitData) =
            abi.decode(_data, (EASInfo, address, bytes));

        __HackathonQVStrategy_init(_poolId, _easInfo, _nft, _qvSimpleInitData);
    }

    /// @dev Initializes the strategy.
    // @solhint disable-next-line func-name-mixedcase
    function __HackathonQVStrategy_init(uint256 _poolId, EASInfo memory _easInfo, address _nft, bytes memory _data)
        internal
    {
        (
            bool _metadataRequired,
            uint256 _maxVoiceCreditsPerAllocator,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (bool, uint256, uint256, uint256, uint256, uint256));

        __QVBaseStrategy_init(
            _poolId,
            true, // _registryGating
            _metadataRequired,
            0, // reviewThreshold
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );

        maxVoiceCreditsPerAllocator = _maxVoiceCreditsPerAllocator;

        __SchemaResolver_init(_easInfo.eas);

        easInfo = EASInfo({
            eas: _easInfo.eas,
            schemaRegistry: _easInfo.schemaRegistry,
            schema: _easInfo.schema,
            schemaUID: _easInfo.schemaUID,
            revocable: _easInfo.revocable
        });

        nft = ERC721(_nft);

        // register / validate SchemaRecord
        if (bytes(_easInfo.schema).length > 0) {
            // if the schema is present, then register schema and update uid
            easInfo.schemaUID =
                schemaRegistry.register(_easInfo.schema, ISchemaResolver(address(this)), _easInfo.revocable);
        } else {
            // compare SchemaRecord to data passed in
            SchemaRecord memory record = schemaRegistry.getSchema(_easInfo.schemaUID);
            if (
                record.uid != _easInfo.schemaUID || record.revocable != _easInfo.revocable
                    || keccak256(abi.encode(record.schema)) != keccak256(abi.encode(_easInfo.schema))
            ) {
                revert INVALID_SCHEMA();
            }
        }
    }

    /// ======================
    /// ====== External ======
    /// ======================

    /// Set the allowed recipient IDs
    /// @param _recipientIds The recipient IDs to allow
    /// @param _expirationTime The expiration time of the attestation
    /// @param _data The data to include in the attestation
    function setAllowedRecipientIds(address[] memory _recipientIds, uint64 _expirationTime, bytes memory _data)
        external
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];
            if (recipientIdToUID[recipientId] != 0) {
                revert ALREADY_ADDED();
            }

            recipientIdToUID[recipientId] = _grantEASAttestation(_recipientIds[i], _expirationTime, _data, 0);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the winner payoutPercentages per rank
    /// @param _payoutPercentages The payoutPercentages to set
    function setPayoutPercentages(uint256[] memory _payoutPercentages)
        external
        onlyPoolManager(msg.sender)
        onlyBeforeAllocation
    {
        uint256 percentageLength = _payoutPercentages.length;
        uint256 totalPayoutPercentages = 0;

        // ensure that the list is sorted in the right order (0: first place, 1: second place, etc.)
        if (_payoutPercentages[0] <= _payoutPercentages[percentageLength - 1]) {
            revert INVALID();
        }

        for (uint256 i = 0; i < percentageLength;) {
            uint256 payoutPercentage = _payoutPercentages[i];
            payoutPercentages[i] = payoutPercentage;
            totalPayoutPercentages += payoutPercentage;
            unchecked {
                i++;
            }
        }

        if (totalPayoutPercentages != 1e18) {
            revert INVALID();
        }
    }

    /// @notice Get the payouts for the recipients
    /// @return The payouts as an array of PayoutSummary structs
    function getPayouts(address[] memory, bytes[] memory)
        public
        view
        virtual
        override
        returns (PayoutSummary[] memory)
    {
        uint256 recipientLength = payoutPercentages.length;

        PayoutSummary[] memory payouts = new PayoutSummary[](recipientLength);

        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = indexToRecipientId[i];
            payouts[i] = _getPayout(recipientId, "");

            unchecked {
                i++;
            }
        }

        return payouts;
    }

    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        uint256 payoutPercentage = payoutPercentages[recipientIdToIndex[_recipientId]];
        uint256 amount = poolAmount * payoutPercentage / 1e18;

        return PayoutSummary(recipients[_recipientId].recipientAddress, amount);
    }

    /// =========================
    /// == Internal Functions ===
    /// =========================

    /// @notice Submit application to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        if (recipientIdToUID[recipientId] == 0) {
            revert UNAUTHORIZED();
        }
        super._registerRecipient(_data, _sender);
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override {
        (address recipientId, uint256 nftId, uint256 voiceCreditsToAllocate) =
            abi.decode(_data, (address, uint256, uint256));

        // check that the sender can allocate votes
        if (nft.ownerOf(nftId) != _sender) {
            revert UNAUTHORIZED();
        }

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (voiceCreditsToAllocate + voiceCreditsUsedPerNftId[nftId] > maxVoiceCreditsPerAllocator) {
            revert INVALID();
        }

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);

        voiceCreditsUsedPerNftId[nftId] += voiceCreditsToAllocate;

        TmpRecipient memory tmp = TmpRecipient({recipientId: address(0), voteRank: 0, foundRecipientAtIndex: 0});

        uint256 totalWinners = payoutPercentages.length;

        if (recipient.totalVotesReceived > votesByRank[totalWinners - 1]) {
            for (uint256 i = 0; i < totalWinners;) {
                // if a new winner was added, push the rest of the list by 1
                if (tmp.foundRecipientAtIndex > 0 && tmp.recipientId != address(0)) {
                    // if the recipient was part of the list (duplicate after adding him again) and got overwritten, we do not need to push the rest of the list
                    if (tmp.recipientId == recipientId) {
                        break;
                    }

                    // get values of the next index
                    // store the previous winner at index i in tmp variables
                    uint256 _tmpVoteRank;
                    address _tmpRecipient;
                    _tmpVoteRank = votesByRank[i];
                    _tmpRecipient = indexToRecipientId[i];

                    // update the values of the next index to the tmp values
                    // update winner at index i to tmp.recipientId (set at previous iteration)
                    votesByRank[i] = tmp.voteRank;
                    indexToRecipientId[i] = tmp.recipientId;

                    recipientIdToIndex[tmp.recipientId] = i;

                    // update the temp values to the next index values
                    tmp.voteRank = _tmpVoteRank;
                    tmp.recipientId = _tmpRecipient;
                }

                // if recipient is in winner list add him and store the temp values to push the rest of the list by 1 in the next loop
                if (tmp.foundRecipientAtIndex == 0 && recipient.totalVotesReceived > votesByRank[i]) {
                    tmp.foundRecipientAtIndex = i;
                    // store the previous winner at index i in tmp variables
                    tmp.voteRank = votesByRank[i];
                    tmp.recipientId = indexToRecipientId[i];

                    // update winner at index i to recipient
                    votesByRank[i] = recipient.totalVotesReceived;
                    indexToRecipientId[i] = recipientId;

                    recipientIdToIndex[recipientId] = i;

                    // break if rest of the list is empty
                    if (tmp.recipientId == address(0)) {
                        break;
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }

    /// @dev Grant EAS attestation to recipient with the EAS contract.
    /// @param _recipientId The recipient ID to grant the attestation to.
    /// @param _expirationTime The expiration time of the attestation.
    /// @param _data The data to include in the attestation.
    /// @param _value The value to send with the attestation.
    function _grantEASAttestation(address _recipientId, uint64 _expirationTime, bytes memory _data, uint256 _value)
        internal
        returns (bytes32)
    {
        AttestationRequest memory attestationRequest = AttestationRequest(
            easInfo.schemaUID,
            AttestationRequestData({
                recipient: _recipientId,
                expirationTime: _expirationTime,
                revocable: easInfo.revocable,
                refUID: _NO_RELATED_ATTESTATION_UID,
                data: _data,
                value: _value
            })
        );

        return easInfo.eas.attest(attestationRequest);
    }

    /// =========================
    /// ==== EAS Functions =====
    /// =========================

    // Note: EAS Information - Supported Testnets
    // Version: 0.27
    // * OP Goerli
    //    EAS Contract: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
    //    Schema Registry: 0x0a7E2Ff54e76B8E6659aedc9103FB21c038050D0
    // * Sepolia
    //    EAS Contract: 0x1a5650d0ecbca349dd84bafa85790e3e6955eb84
    //    Schema Registry: 0x7b24C7f8AF365B4E308b6acb0A7dfc85d034Cb3f

    /// @dev Gets an attestation from the EAS contract using the UID
    /// @param uid The UUID of the attestation to get.
    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        return easInfo.eas.getAttestation(uid);
    }

    /// @dev Gets a schema from the SchemaRegistry contract using the UID
    /// @param uid The UID of the schema to get.
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return schemaRegistry.getSchema(uid);
    }

    /// @notice Returns if the attestation is payable or not
    /// @return True if the attestation is payable, false otherwise
    function isPayable() public pure override returns (bool) {
        return false;
    }

    /// @notice Returns if the attestation is expired or not
    /// @param _recipientId The recipient ID to check
    function isAttestationExpired(address _recipientId) public view returns (bool) {
        if (easInfo.eas.getAttestation(recipientIdToUID[_recipientId]).expirationTime < block.timestamp) {
            return true;
        }
        return false;
    }

    function onAttest(Attestation calldata, uint256) internal pure override returns (bool) {
        return true;
    }

    function onRevoke(Attestation calldata, uint256) internal pure override returns (bool) {
        return true;
    }

    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == InternalRecipientStatus.Accepted;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view virtual override returns (bool) {
        return nft.balanceOf(_allocator) > 0;
    }
}
