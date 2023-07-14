// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseStrategy} from "../../BaseStrategy.sol";
import {Payouts} from "../../../core/libraries/Payouts.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

abstract contract RFPAllocationStrategy is BaseStrategy, ReentrancyGuard {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error ALLOCATION_DONE();
    error NOT_ALLOCATED();
    error NOT_IMPLEMENTED();
    error NOT_ELIGIBLE();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    bool public payoutReady;
    uint256 private _counter;
    address public acceptedRecipientId;

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        address payoutAddress;
        uint256 proposalAmount;
        RecipientStatus recipientStatus;
    }

    ///@notice recipientId -> PayoutSummary
    mapping(address => Payouts.PayoutSummary) public payoutSummaries;

    /// @notice recipientId -> Recipient
    mapping(address => Recipient) public recipients;

    /// ======================
    /// ======= Events =======
    /// ======================

    event RecipientSubmitted(
        address indexed recipientId, address payoutAddress, Metadata metadata, address indexed sender
    );
    event Allocated(bytes data, address indexed allocator);

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Submit proposal to RFP pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function registerRecipients(bytes memory _data, address _sender)
        external
        payable
        override
        onlyAllo
        returns (address)
    {
        if (payoutReady) {
            revert ALLOCATION_DONE();
        }

        (address payoutAddress, uint256 proposalAmount, Metadata memory metadata) =
            abi.decode(_data, (address, uint256, Metadata));

        Recipient memory recipient = Recipient({
            payoutAddress: payoutAddress,
            proposalAmount: proposalAmount,
            recipientStatus: RecipientStatus.Pending
        });

        address recipientId = address(uint160(_counter++));
        recipients[recipientId] = recipient;

        emit RecipientSubmitted(recipientId, payoutAddress, metadata, _sender);

        return recipientId;
    }

    /// @notice Checks if msg.sender is eligible for RFP allocation
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return recipients[_recipientId].recipientStatus;
    }

    /// @notice Select recipient for RFP allocation
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function allocate(bytes memory _data, address _sender) external payable override onlyAllo nonReentrant {
        if (!allo.isPoolManager(poolId, _sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }

        if (payoutReady) {
            revert ALLOCATION_DONE();
        }

        address approvedRecipientId = abi.decode(_data, (address));

        for (uint256 i = 0; i < _counter;) {
            address recipientId = address(uint160(i));
            if (recipientId == approvedRecipientId) {
                recipients[recipientId].recipientStatus = RecipientStatus.Accepted;
                acceptedRecipientId = recipientId;
            }

            recipients[recipientId].recipientStatus = RecipientStatus.Rejected;

            unchecked {
                i++;
            }
        }

        payoutReady = true;
        emit Allocated(_data, _sender);
    }

    /// @notice Get the payout summary for accepted recipient
    function getPayout(address[] memory, bytes memory)
        external
        view
        returns (Payouts.PayoutSummary[] memory summaries)
    {
        summaries = new Payouts.PayoutSummary[](1);
        summaries[0] = Payouts.PayoutSummary({
            recipient: recipients[acceptedRecipientId].payoutAddress,
            percentage: 1e18,
            amount: recipients[acceptedRecipientId].proposalAmount
        });
    }

    /// @notice Check if the strategy is ready to payout
    function readyToPayout(bytes memory) external view returns (bool) {
        return payoutReady;
    }
}
