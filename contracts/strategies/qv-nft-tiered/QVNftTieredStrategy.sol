// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {ERC721} from "solady/src/tokens/ERC721.sol";
// Core Contracts
import {QVBaseStrategy} from "../qv-base/QVBaseStrategy.sol";

contract QVNftTieredStrategy is QVBaseStrategy {
    /// ======================
    /// ======= Events =======
    /// ======================
    event AllocatedWithNft(address indexed recipientId, uint256 votes, address nft, address allocator);

    /// ======================
    /// ======= Storage ======
    /// ======================

    // NFTs that can be used to allocate votes
    ERC721[] public nfts;

    // NFT -> maxVoiceCredits
    mapping(ERC721 => uint256) public maxVoiceCreditsPerNft;
    // NFT -> nftId -> voiceCreditsUsed
    mapping(ERC721 => mapping(uint256 => uint256)) public voiceCreditsUsedPerNftId;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public override {
        (
            bool _registryGating,
            bool _metadataRequired,
            ERC721[] memory _nfts,
            uint256[] memory _maxVoiceCreditsPerNft,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (bool, bool, ERC721[], uint256[], uint256, uint256, uint256, uint256));
        __QV_NFT_TieredStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            _nfts,
            _maxVoiceCreditsPerNft,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
    }

    /// @dev Internal initialize function that sets the poolId in the base strategy
    function __QV_NFT_TieredStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        ERC721[] memory _nfts,
        uint256[] memory _maxVoiceCreditsPerNft,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __QVBaseStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            0, // reviewThreshold
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );

        uint256 nftsLength = _nfts.length;
        if (nftsLength != _maxVoiceCreditsPerNft.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < nftsLength;) {
            ERC721 nft = _nfts[i];
            nfts.push(nft);
            maxVoiceCreditsPerNft[nft] = _maxVoiceCreditsPerNft[i];
            unchecked {
                i++;
            }
        }
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function isValidAllocator(address _allocator) external view override returns (bool) {
        return _isValidAllocator(_allocator);
    }

    /// =============================
    /// ==== Internal Functions =====
    /// =============================

    function _isValidAllocator(address _allocator) internal view returns (bool) {
        uint256 nftsLength = nfts.length;
        for (uint256 i = 0; i < nftsLength;) {
            if (nfts[i].balanceOf(_allocator) > 0) {
                return true;
            }

            unchecked {
                i++;
            }
        }

        return false;
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override {
        (address recipientId, ERC721 nft, uint256 nftId, uint256 voiceCreditsToAllocate) =
            abi.decode(_data, (address, ERC721, uint256, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // check that the sender can allocate votes
        if (nft.ownerOf(nftId) != _sender) {
            revert UNAUTHORIZED();
        }

        if (!_isAcceptedRecipient(recipientId)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        if (voiceCreditsToAllocate + voiceCreditsUsedPerNftId[nft][nftId] > maxVoiceCreditsPerNft[nft]) {
            revert INVALID();
        }

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);

        // update credits used by nftId
        voiceCreditsUsedPerNftId[nft][nftId] += voiceCreditsToAllocate;

        emit AllocatedWithNft(recipientId, voiceCreditsToAllocate, address(nft), _sender);
    }

    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == InternalRecipientStatus.Accepted;
    }
}
