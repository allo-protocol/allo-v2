// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract DonationVotingStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    /// @notice Struct to hold details of the recipients
    struct Recipient {
        bool isRegistryIdentity;
        address recipientAddress;
        InternalRecipientStatus recipientStatus;
    }

    /// @notice Struct to hold details of the allocations to claim
    struct Claim {
        address recipientId;
        address token;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error UNAUTHORIZED();
    error RECIPIENT_ALREADY_ACCEPTED();
    error REGISTRATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ACTIVE();
    error ALLOCATION_NOT_ENDED();
    error INVALID();
    error DISTRIBUTION_STARTED();
    error NOT_ALLOWED();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event Appealed(address indexed recipientId, bytes data, address sender);
    event Reviewed(address indexed recipientId, InternalRecipientStatus recipientStatus, address sender);
    event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token);

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public registryGating;
    bool public distributionStarted;
    uint256 public registrationStartTime;
    uint256 public registrationEndTime;
    uint256 public allocationStartTime;
    uint256 public allocationEndTime;

    /// @notice token -> bool
    mapping(address => bool) public allowedTokens;
    /// @notice recipientId -> Recipient
    mapping(address => Recipient) private _recipients;
    /// @notice recipientId -> PayoutSummary
    mapping(address => PayoutSummary) public payoutSummaries;
    /// @notice recipientId -> token -> amount
    mapping(address => mapping(address => uint256)) public claims;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    modifier onlyActiveRegistration() {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyActiveAllocation() {
        if (allocationStartTime <= block.timestamp && block.timestamp <= allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
        _;
    }

    modifier onlyAfterAllocation() {
        if (block.timestamp <= allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
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

    function initialize(uint256 _poolId, bytes memory _data) public virtual override {
        (
            bool _registryGating,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime,
            address[] memory _allowedTokens
        ) = abi.decode(_data, (bool, uint256, uint256, uint256, uint256, address[]));
        __DonationVotingStrategy_init(
            _poolId,
            _registryGating,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime,
            _allowedTokens
        );
    }

    function __DonationVotingStrategy_init(
        uint256 _poolId,
        bool _registryGating,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _allocationStartTime,
        uint256 _allocationEndTime,
        address[] memory _allowedTokens
    ) internal {
        __BaseStrategy_init(_poolId);
        registryGating = _registryGating;

        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        uint256 allowedTokensLength = _allowedTokens.length;

        if (allowedTokensLength == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        }

        for (uint256 i = 0; i < allowedTokensLength; i++) {
            allowedTokens[_allowedTokens[i]] = true;
        }
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get Internal recipient status
    /// @param _recipientId Id of the recipient
    function getInternalRecipientStatus(address _recipientId) external view returns (InternalRecipientStatus) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        InternalRecipientStatus internalStatus = _getRecipient(_recipientId).recipientStatus;
        if (internalStatus == InternalRecipientStatus.Appealed) {
            return RecipientStatus.Pending;
        } else {
            return RecipientStatus(uint8(internalStatus));
        }
    }

    /// @notice Returns the payout summary for the accepted recipient
    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (PayoutSummary[] memory payouts)
    {
        uint256 recipientLength = _recipientIds.length;

        payouts = new PayoutSummary[](recipientLength);

        for (uint256 i = 0; i < recipientLength;) {
            payouts[i] = payoutSummaries[_recipientIds[i]];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if address is elgible allocator
    function isValidAllocator(address) external pure returns (bool) {
        return true;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Review recipient application
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, InternalRecipientStatus[] calldata _recipientStatuses)
        external
        onlyPoolManager(msg.sender)
        onlyActiveRegistration
    {
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < recipientLength;) {
            if (
                _recipientStatuses[i] == InternalRecipientStatus.None
                    || _recipientStatuses[i] == InternalRecipientStatus.Appealed
            ) {
                revert INVALID();
            }

            address recipientId = _recipientIds[i];
            InternalRecipientStatus recipientStatus = _recipientStatuses[i];

            Recipient storage recipient = _recipients[recipientId];

            recipient.recipientStatus = recipientStatus;

            emit Reviewed(recipientId, recipientStatus, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Set payout for the recipients
    /// @param _recipientIds Ids of the recipients
    /// @param _amounts Amounts to be paid out
    function setPayout(address[] memory _recipientIds, uint256[] memory _amounts)
        external
        onlyPoolManager(msg.sender)
        onlyAfterAllocation
    {
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _amounts.length) {
            revert INVALID();
        }

        for (uint256 i = 0; i < recipientLength;) {
            address recipientId = _recipientIds[i];

            payoutSummaries[recipientId] = PayoutSummary(_recipients[recipientId].recipientAddress, _amounts[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Claim allocated tokens
    /// @param _claims Claims to be claimed
    function claim(Claim[] calldata _claims) external nonReentrant onlyAfterAllocation {
        uint256 claimsLength = _claims.length;
        for (uint256 i; i < claimsLength;) {
            Claim memory singleClaim = _claims[i];
            Recipient memory recipient = _recipients[singleClaim.recipientId];
            uint256 amount = claims[singleClaim.recipientId][singleClaim.token];

            claims[singleClaim.recipientId][singleClaim.token] = 0;
            _transferAmount(singleClaim.token, recipient.recipientAddress, amount);

            emit Claimed(singleClaim.recipientId, recipient.recipientAddress, amount, singleClaim.token);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Withdraw funds from pool
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        if (block.timestamp <= allocationEndTime + 30 days) {
            revert NOT_ALLOWED();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);
        if (pool.amount < _amount) {
            revert UNAUTHORIZED();
        }

        // TODO: This can cause pool owner stealing funds

        allo.decreasePoolTotalFunding(poolId, _amount);
        _transferAmount(pool.token, msg.sender, _amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Returns status of the pool
    function _isPoolActive() internal view override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Submit application to pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        if (_recipients[recipientId].recipientStatus == InternalRecipientStatus.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        address recipientAddress;
        bool isRegistryIdentity;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            if (!_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, isRegistryIdentity, metadata) = abi.decode(_data, (address, bool, Metadata));
            recipientId = _sender;
            if (isRegistryIdentity && !_isIdentityMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        if (recipientAddress == address(0)) {
            revert INVALID();
        }

        Recipient storage recipient = _recipients[recipientId];

        if (_recipients[recipientId].recipientAddress == address(0)) {
            // new recipient
            recipient.recipientAddress = recipientAddress;
            recipient.isRegistryIdentity = registryGating ? true : isRegistryIdentity;
            recipient.recipientStatus = InternalRecipientStatus.Pending;
        } else {
            // existing recipient
            recipient.recipientAddress = recipientAddress;
            if (recipient.recipientStatus == InternalRecipientStatus.Rejected) {
                recipient.recipientStatus = InternalRecipientStatus.Appealed;
                emit Appealed(recipientId, _data, _sender);
            } else {
                recipient.recipientStatus = InternalRecipientStatus.Pending;
                emit Registered(recipientId, _data, _sender);
            }
        }
    }

    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        onlyActiveAllocation
    {
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));

        Recipient storage recipient = _recipients[recipientId];

        if (recipient.recipientStatus != InternalRecipientStatus.Accepted) {
            revert INVALID();
        }

        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        _transferAmount(token, address(this), amount);

        claims[recipientId][token] += amount;

        emit Allocated(recipientId, amount, token, _sender);
    }

    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        uint256 recipientLength = _recipientIds.length;
        for (uint256 i; i < recipientLength;) {
            address recipientId = _recipientIds[i];

            Recipient storage recipient = _recipients[recipientId];

            if (recipient.recipientStatus != InternalRecipientStatus.Accepted) {
                revert INVALID();
            }

            uint256 amount = payoutSummaries[recipientId].amount;

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            emit Distributed(recipientId, recipient.recipientAddress, amount, _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if sender is identity owner or member
    /// @param _anchor Anchor of the identity
    /// @param _sender The sender of the transaction
    function _isIdentityMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry registry = allo.getRegistry();
        IRegistry.Identity memory identity = registry.getIdentityByAnchor(_anchor);
        return registry.isOwnerOrMemberOfIdentity(identity.id, _sender);
    }

    /// @notice Get the recipient
    /// @param _recipientId Id of the recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return _recipients[_recipientId];
    }
}
