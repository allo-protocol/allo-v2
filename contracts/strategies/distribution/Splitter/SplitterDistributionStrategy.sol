// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllocationStrategy} from "../../../interfaces/IAllocationStrategy.sol";
import {IDistributionStrategy} from "../../../interfaces/IDistributionStrategy.sol";
import {Allo} from "../../../core/Allo.sol";
import {Transfer} from "../../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract SplitterDistributionStrategy is IDistributionStrategy, Transfer, ReentrancyGuard {
    /// @notice Custom errors
    error STRATEGY_ALREADY_INITIALIZED();
    error UNAUTHORIZED();
    error PAYOUT_NOT_READY();
    error PAYOUT_FINALIZED();
    error ALREADY_DISTRIBUTED();

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    Allo public allo;
    bool public initialized;
    bytes32 public identityId;
    uint256 public poolId;
    uint256 public amount;
    address public token;

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    /// Recipient.id -> amount paid
    mapping(uint256 => uint256) public paidAmounts;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address allo, bytes32 identityId, uint256 indexed poolId, address token, bytes data);
    event PayoutsDistributed(uint256[] recipientIds, PayoutSummary[] payoutSummary, address sender);
    event PoolFundingIncreased(uint256 amount);

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    /// @notice Modifier to check if the caller is the Allo contract
    modifier onlyAllo() {
        if (msg.sender != address(allo) || address(allo) == address(0)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Modifier to check if the caller is a pool manager
    modifier onlyPoolManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// @notice Initialize the contract
    /// @param _allo The address of the Allo contract
    /// @param _identityId The identityId of the pool
    /// @param _poolId The poolId of the pool
    /// @param _token The pool token
    /// @param _data unused for this strategy
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, address _token, bytes memory _data)
        external
        override
        onlyAllo
    {
        if (initialized) {
            revert STRATEGY_ALREADY_INITIALIZED();
        }

        initialized = true;

        allo = Allo(_allo);
        identityId = _identityId;
        poolId = _poolId;
        token = _token;

        emit Initialized(_allo, _identityId, _poolId, _token, _data);
    }

    /// @notice Distribute the payouts to the recipients
    /// @param _recipientIds The recipientIds to distribute to
    /// @param _data encoded bytes passed to the allocation strategy
    /// @param _sender The sender of the payouts
    function distribute(uint256[] memory _recipientIds, bytes calldata _data, address _sender)
        external
        onlyAllo
        nonReentrant
    {
        IAllocationStrategy allocationStrategy = IAllocationStrategy(allo.getAllocationStrategy(poolId));

        if (!allocationStrategy.readyToPayout("0x")) {
            revert PAYOUT_NOT_READY();
        }

        PayoutSummary[] memory payouts = allocationStrategy.getPayout(_recipientIds, _data);

        uint256 recipientIdsLength = _recipientIds.length;

        for (uint256 i = 0; i < recipientIdsLength;) {
            uint256 recipientId = _recipientIds[i];

            if (paidAmounts[recipientId] > 0) {
                revert ALREADY_DISTRIBUTED();
            }

            uint256 amountToTransfer = (amount * payouts[i].percentage) / 1e18;

            paidAmounts[recipientId] = amountToTransfer;

            _transferAmount(token, payouts[i].payoutAddress, amountToTransfer);
            unchecked {
                i++;
            }
        }

        emit PayoutsDistributed(_recipientIds, payouts, _sender);
    }

    /// @notice invoked via allo.fundPool to update pool's amount
    /// @param _amount amount by which pool is increased
    function poolFunded(uint256 _amount) external onlyAllo {
        if (IAllocationStrategy(allo.getAllocationStrategy(poolId)).readyToPayout("0x")) {
            revert PAYOUT_FINALIZED();
        }
        amount += _amount;
        emit PoolFundingIncreased(amount);
    }

    receive() external payable onlyAllo {}
}
