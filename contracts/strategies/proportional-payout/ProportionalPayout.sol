// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {Allo} from "../core/Allo.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {Transfer} from "../core/libraries/Transfer.sol";

contract ProportionalPayout is BaseStrategy {
    /// @notice The maximum number of recipients allowed
    /// @dev This is both to keep the number of choices low and to avoid gas issues 
    uint256 constant MAX_RECIPIENTS = 3;

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice When the allocation (voting) period starts
    uint256 public startTime;

    /// @notice When the allocation (voting) period ends
    uint256 public endTime;

    /// @notice The token required for voting
    ERC20 public token;

    /// @notice List of recipients who will receive payout at the end
    address[] public recipients;

    /// @notice Whether or not a recipient is valid
    mapping(address => bool) public isRecipient;

    /// @notice Votes for each recipient
    mapping(address => uint256) public votes;

    /// @notice Whether or not a voter has voted
    /// @dev This is to prevent double voting
    mapping(address => bool) public hasVoted;

    /// @notice Total number of votes cast
    /// @dev This is used to calculate the percentage of votes for each recipient at the end
    uint256 public totalVotes;

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error BadTimes();
    error NotWithinAllocationPeriod();
    error AlreadyAllocated();
    error NotElligibleVoter();
    error AllocationHasntEnded();
    error TooManyRecipients();

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Modifiers ===========
    /// ===============================

    modifier onlyDuringAllocationPeriod() {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert NotWithinAllocationPeriod();
        }
        _;
    }

    /// ===============================
    /// ========= Functions ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        super.initialize(_poolId, _data);
        (token, startTime, endTime) = abi.decode(_data, (ERC20, uint256, uint256));

        if (startTime >= endTime || endTime < block.timestamp) {
            revert BadTimes();
        }
    }

    function registerRecipients(
        bytes memory _data,
        address _sender
    ) external
      payable 
      onlyDuringAllocationPeriod 
      onlyAllo 
      returns (address) {
        if (recipients.length == MAX_RECIPIENTS) {
            revert RECIPIENT_MAX_REACHED();
        }

        address[] memory _recipients = abi.decode(_data, (address[]));

        if (_recipients.length > MAX_RECIPIENTS) {
            revert TooManyRecipients();
        }

        for (uint256 i; i < _recipients.length; i++) {
            isRecipient[_recipients[i]] = true;
            recipients.push(_recipients[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getRecipientStatus(address _recipientId) public view returns
    (RecipientStatus) {
        if (isRecipient[_recipientId]) {
            return RecipientStatus.Accepted;
        } else {
            return RecipientStatus.None;
        }
    }

    function isValidAllocator(address _allocator) public view returns (bool) {
        return token.balanceOf[_allocator] > 0;
    }

    function allocate(
        bytes memory _data,
        address _sender
    ) external payable
    onlyDuringAllocationPeriod onlyAllo {
        if (hasVoted[_sender]) {
            revert AlreadyAllocated();
        }

        (address _recipient, uint256 _amount) = abi.decode(_data, (address, uint256));

        if (!isRecipient[_recipient]) {
            revert NotElligibleVoter();
        }

        hasVoted[_sender] = true;
        votes[_recipient] += _amount;
        totalVotes += _amount;
    }

    function getPayouts(
        address[] memory _recipientIds,
        bytes memory _data,
        address _sender
    ) external view returns (uint256[] memory) {
        if (block.timestamp < endTime) {
            revert AllocationHasntEnded();
        }

        uint256[] memory payouts = new uint[](_recipientIds.length);

        // Get pool size
        (,,, uint256 _poolSize,,,) = allo.pools(poolId)

        // loop through recipients
        for (uint256 i; i < _recipientIds.length; i++) {
            if (isRecipient[_recipientIds[i]]) {
                // get votes for recipient as percentage of total votes
                payouts[i] = votes[_recipientIds[i]] * _poolSize / totalVotes;
            }
        }

        return payouts;
    }

    function distribute(
        address[] memory _recipientIds,
        bytes memory _data,
        address _sender
    ) external onlyAllo {
        // Check that round has ended
        if (block.timestamp < endTime) {
            revert AllocationHasntEnded();
        }

        // Get distribution
        (,, address tokenToDistribute, uint256 amountToDistribute,,,) = allo.pools(poolId);
        uint256[] memory _payouts = getPayouts(_recipientIds, _data, _sender);

        // Transfer pool to recipients
        for (uint256 i; i < _recipientIds.length; i++) {
            _transferAmount(
                tokenToDistribute,
                _recipientIds[i],
                _payouts[i]
            )
        }
    }
}
