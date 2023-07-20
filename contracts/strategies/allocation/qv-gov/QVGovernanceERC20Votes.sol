// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {QVSimpleStrategy} from "../../qv-simple/QVSimpleStrategy.sol";
import "@openzeppelin/governance/utils/IVotes.sol";

contract QVGovernanceERC20Votes is QVSimpleStrategy {
    constructor(address _allo, string memory _name) QVSimpleStrategy(_allo, _name) {}

    IVotes public govToken;
    uint256 public timestamp;
    uint256 public reviewThreshold;

    mapping(address => mapping(InternalRecipientStatus => uint256)) public reviewsByStatus;

    /// @notice Initialize the strategy
    /// @param _poolId The pool id
    /// @param _data The data
    function initialize(uint256 _poolId, bytes memory _data) public override {
        (
            address _govToken,
            uint256 _timestamp,
            uint256 _reviewThreshold,
            bool _registryGating,
            bool _metadataRequired,
            uint256 _maxVoiceCreditsPerAllocator,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (address, uint256, uint256, bool, bool, uint256, uint256, uint256, uint256, uint256));
        __QVGovernanceERC20Votes_init(
            _govToken,
            _timestamp,
            _reviewThreshold,
            _poolId,
            _registryGating,
            _metadataRequired,
            _maxVoiceCreditsPerAllocator,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
    }

    function __QVGovernanceERC20Votes_init(
        address _govToken,
        uint256 _timestamp,
        uint256 _reviewThreshold,
        uint256 _poolId,
        bool _registryGating,
        bool _metadataRequired,
        uint256 _maxVoiceCreditsPerAllocator,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime
    ) internal {
        __QVSimpleStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            _maxVoiceCreditsPerAllocator,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
        govToken = IVotes(_govToken);
        timestamp = _timestamp;
        reviewThreshold = _reviewThreshold;

        // todo: test if it actually works
        // sanity check if token is ERC20Votes, should revert is function is not available
        govToken.getPastVotes(address(this), 0);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Review recipient application
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, InternalRecipientStatus[] calldata _recipientStatuses)
        external
        override
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < recipientLength;) {
            InternalRecipientStatus recipientStatus = _recipientStatuses[i];
            address recipientId = _recipientIds[i];
            if (recipientStatus == InternalRecipientStatus.None || recipientStatus == InternalRecipientStatus.Appealed)
            {
                revert RECIPIENT_ERROR(recipientId);
            }

            // Check if recipient has
            reviewsByStatus[recipientId][recipientStatus]++;

            if (reviewsByStatus[recipientId][recipientStatus] >= reviewThreshold) {
                Recipient storage recipient = recipients[recipientId];
                recipient.recipientStatus = recipientStatus;
            }

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                i++;
            }
        }
    }
}
