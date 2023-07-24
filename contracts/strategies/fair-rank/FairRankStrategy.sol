// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title FairRankStrategy
/// @notice Strategy contract for FairRank base on https://observablehq.com/@andytudhope/fair-rank
/// @dev This strategy is used to allocate funds to recipients based on a fair rank using GTC as the voting token
// NOTE:
contract FairRankStrategy is BaseStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error INSUFFICIENT_GTC_BALANCE();

    /// ======================
    /// ======= Storage ======
    /// ======================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        InReview
    }

    /// @notice The grantee or Recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        uint256 totalVotes;
        Metadata metadata;
        InternalRecipientStatus recipientStatus;
    }

    IERC20 internal gtc;

    uint256 internal constant TOTAL_GTC_MINTED = 100_000_000;
    uint256 public ceilingPercent;

    mapping(address => Recipient) internal recipients;

    /// ======================
    /// ======= Events =======
    /// ======================

    /// ======================
    /// ====== Modifiers =====
    /// ======================

    modifier hasEnoughGtc(uint256 _amount) {
        if (gtc.balanceOf(msg.sender) < _amount) {
            revert INSUFFICIENT_GTC_BALANCE();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external override {
        (address _gtc) = abi.decode(_data, (address));
        gtc = IERC20(_gtc);

        __FairRankStrategy_init(_poolId);
    }

    function __FairRankStrategy_init(uint256 _poolId) internal {
        __BaseStrategy_init(_poolId);
    }

    /// ===============================
    /// ====== View  Functions ========
    /// ===============================

    function ceiling() external view returns (uint256) {
        return TOTAL_GTC_MINTED * (ceilingPercent / 100);
    }

    /// ===============================
    /// ======= Custom Functions ======
    /// ===============================

    function setCeilingPercentage(uint256 _ceilingPercent) external onlyPoolManager(msg.sender) {
        ceilingPercent = _ceilingPercent;
    }

    /// @notice Upvote a grantee/recipient
    /// @param _recipientId The recipient id you are upvoting
    // Note: It costs GTC to cast a upvote and GTC will be staked in the contract
    function upvote(address _recipientId, uint256 _tokenAmount) external hasEnoughGtc(_tokenAmount) {
        // calculate the percentage of the total GTC minted
        uint256 percentage = (_tokenAmount / TOTAL_GTC_MINTED) * 100;
        // todo: check if percentage is greater than ceiling

        // transfer GTC from sender to this contract
        gtc.transferFrom(msg.sender, address(this), _tokenAmount);

        // add votes to recipient
        recipients[_recipientId].totalVotes += _tokenAmount;
    }

    /// @notice Downvote a grantee/recipient
    /// @param _recipientId The recipient id you are downvoting
    // Note: It costs less GTC to downvote and the GTC will be burned
    function downvote(address _recipientId, uint256 _tokenAmount) external hasEnoughGtc(_tokenAmount) {
        // calculate the cost per vote
        uint256 costPerVote = _tokenAmount / recipients[_recipientId].totalVotes;

        // burn the GTC from the sender
        // Note: have to see if burn is available on the token contract?
        // otherwise we need a new plan other than burning...
        // gtc.burn(msg.sender, _tokenAmount);

        // remove votes from recipient
        recipients[_recipientId].totalVotes -= _tokenAmount;
    }

    /// ===============================
    /// ====== Interface Functions ====
    /// ===============================

    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address) {}

    function _allocate(bytes memory _data, address _sender) internal override {}

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {}

    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus) {}

    function getPayouts(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {}

    function isValidAllocator(address _allocator) external view returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }
}
