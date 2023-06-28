// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllocationStrategy} from "../../interfaces/IAllocationStrategy.sol";
import {IDistributionStrategy} from "../../interfaces/IDistributionStrategy.sol";
import {Allo} from "../../core/Allo.sol";
import {Transfer} from "../../core/libraries/Transfer.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

contract SplitterDistributionStrategy is IDistributionStrategy, Transfer, ReentrancyGuard {
    /// @notice Custom errors
    error STRATEGY_ALREADY_INITIALIZED();
    error UNAUTHORIZED();
    error PAYOUT_NOT_READY();
    error PAYOUT_FINALIZED();

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    Allo public allo;
    bytes32 public identityId;
    uint256 public poolId;
    bool public initialized;
    address public token;

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================
    uint256 public totalAmount;
    mapping(uint256 => uint256) public applicationIdToPaidAmount;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Initialized(address indexed _allo, bytes32 indexed _identityId, uint256 indexed _poolId, address _token);
    event PayoutsDistributed(uint256[] _applicationIds, address _sender);
    event PoolFunded(uint256 _amount);

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
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, address _token, bytes memory _data)
        external
        override
        onlyAllo
    {
        _data;
        if (initialized) {
            revert STRATEGY_ALREADY_INITIALIZED();
        }

        initialized = true;

        allo = Allo(_allo);
        identityId = _identityId;
        poolId = _poolId;
        token = _token;

        emit Initialized(_allo, _identityId, _poolId, _token);
    }

    /// @notice Distribute the payouts to the recipients
    /// @param _applicationIds The applicationIds to distribute to
    /// @param _sender The sender of the payouts
    function distribute(uint256[] memory _applicationIds, bytes memory, address _sender)
        external
        onlyAllo
        nonReentrant
    {
        IAllocationStrategy allocationStrategy = IAllocationStrategy(allo.getAllocationStrategy(poolId));

        if (!allocationStrategy.readyToPayout()) {
            revert PAYOUT_NOT_READY();
        }

        PayoutSummary[] memory payouts = allocationStrategy.getPayout(_applicationIds, "0x");

        uint256 applicationIdsLength = _applicationIds.length;

        for (uint256 i = 0; i < applicationIdsLength;) {
            uint256 transferAmount = (totalAmount * payouts[i].percentage) / 1e18;

            transferAmount -= applicationIdToPaidAmount[_applicationIds[i]];
            applicationIdToPaidAmount[_applicationIds[i]] += transferAmount;

            _transferAmount(token, payouts[i].recipient, transferAmount);
            unchecked {
                i++;
            }
        }
        emit PayoutsDistributed(_applicationIds, _sender);
    }

    /// @notice Tracks the pool amount to distribute
    /// @param _amount The amount to add to the pool
    function poolFunded(uint256 _amount) external onlyAllo {
        if (IAllocationStrategy(allo.getAllocationStrategy(poolId)).readyToPayout()) {
            revert PAYOUT_FINALIZED();
        }
        totalAmount += _amount;
        // emit event
        emit PoolFunded(_amount);
    }
}
