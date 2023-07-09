// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseAllocationStrategy} from "../BaseAllocationStrategy.sol";
import {SimpleProjectRegistry} from "./SimpleProjectRegistry.sol";

abstract contract AltRegistryGating is BaseAllocationStrategy {
    /// ======================
    /// ======= Errors =======
    /// ======================

    error NOT_IMPLEMENTED();
    error REGISTRATION_FAILED();
    error ALREADY_REGISTERED();
    error INVALID_DATA();

    /// =================================
    /// === Custom Storage Variables ====
    /// =================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        address payoutAddress;
        RecipientStatus recipientStatus;
        uint256 percentage;
    }

    /// @notice Simple registry to auto approve recipients
    SimpleProjectRegistry public simpleProjectRegistry;

    /// @notice project -> Recipient
    mapping(address => Recipient) public recipients;

    bool public payoutReady;
    bool public poolOpen;

    /// ======================
    /// ======= Events =======
    /// ======================

    event Allocated(bytes data, address indexed allocator);
    event PoolOpen(bool poolOpen);
    event PayoutReady(bool payoutReady);

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the allocation strategy
    /// @param _allo Address of the Allo contract
    /// @param _identityId Id of the identity
    /// @param _poolId Id of the pool
    /// @param _data The data to be decoded
    /// @dev This function is called by the Allo contract
    function initialize(address _allo, bytes32 _identityId, uint256 _poolId, bytes memory _data) public override {
        super.initialize(_allo, _identityId, _poolId, _data);

        // decode data custom to this strategy
        (address _simpleProjectRegistry) = abi.decode(_data, (address));
        if (_simpleProjectRegistry == address(0)) {
            revert INVALID_ADDRESS();
        }

        simpleProjectRegistry = SimpleProjectRegistry(_simpleProjectRegistry);
    }

    /// @notice apply to the pool
    function registerRecipients(bytes memory _data, address) external payable override returns (address) {
        (address project, address payoutAddress) = abi.decode(_data, (address, address));
        if (project == address(0) || payoutAddress == address(0)) {
            revert INVALID_ADDRESS();
        }
        if (!poolOpen && !simpleProjectRegistry.projects(project)) {
            revert REGISTRATION_FAILED();
        }
        if (recipients[project].payoutAddress == address(0)) {
            revert ALREADY_REGISTERED();
        }

        // auto approval
        recipients[project] =
            Recipient({payoutAddress: payoutAddress, recipientStatus: RecipientStatus.Accepted, percentage: 0});

        return project;
    }

    /// @notice Returns the status of the recipient
    /// @param _recipientId The recipientId of the recipient
    function getRecipientStatus(address _recipientId) external view override returns (RecipientStatus) {
        return recipients[_recipientId].recipientStatus;
    }

    /// @notice Set allocations by pool manager
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function allocate(bytes memory _data, address _sender) external payable override onlyAllo {
        // decode data
        (address[] memory projects, uint256[] memory percentages) = abi.decode(_data, (address[], uint256[]));

        uint256 allocationsLength = percentages.length;

        if (projects.length != allocationsLength) {
            revert INVALID_DATA();
        }

        for (uint256 i = 0; i < allocationsLength;) {
            address project = projects[i];
            if (recipients[project].recipientStatus != RecipientStatus.Accepted) {
                revert INVALID_DATA();
            }

            recipients[project].percentage = percentages[i];

            unchecked {
                i++;
            }
        }

        emit Allocated(_data, _sender);
    }

    /// @notice Get the payout summary for recipients
    /// @param _recipientId Array of recipient ids
    function getPayout(address[] memory _recipientId, bytes memory)
        external
        view
        override
        returns (PayoutSummary[] memory summaries)
    {
        uint256 recipientIdLength = _recipientId.length;
        summaries = new PayoutSummary[](recipientIdLength);

        for (uint256 i = 0; i < recipientIdLength;) {
            Recipient memory recipient = recipients[_recipientId[i]];
            summaries[i] = PayoutSummary({payoutAddress: recipient.payoutAddress, percentage: recipient.percentage});

            unchecked {
                i++;
            }
        }
    }

    /// @notice Check if the strategy is ready to payout
    function readyToPayout(bytes memory) external view override returns (bool) {
        return payoutReady && !poolOpen;
    }

    /// @notice Set if the pool is open
    /// @param _poolOpen The status of the pool
    function setIsPoolOpen(bool _poolOpen) external onlyPoolManager {
        poolOpen = _poolOpen;
        emit PoolOpen(_poolOpen);
    }

    /// @notice Set if the pool is ready to payout
    /// @param _payoutReady The status of the pool
    function setIsPayoutReady(bool _payoutReady) external onlyPoolManager {
        payoutReady = _payoutReady;
        emit PayoutReady(_payoutReady);
    }
}
