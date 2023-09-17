// SPDX-License Identifier: MIT
pragma solidity ^0.8.19;

import {QVBaseStrategy} from "../../contracts/strategies/qv-base/QVBaseStrategy.sol";

contract QVBaseStrategyTestMock is QVBaseStrategy {
    constructor(address allo, string memory name) QVBaseStrategy(allo, name) {}

    /// @notice Returns if the recipient is accepted
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address) internal pure override returns (bool) {
        return true;
    }

    function _isValidAllocator(address) internal view virtual override returns (bool) {
        return true;
    }

    function _hasVoiceCreditsLeft(uint256, uint256) internal pure override returns (bool) {
        return true;
    }

    function initialize(uint256 _poolId, bytes memory _data) public virtual override onlyAllo {
        (QVBaseStrategy.InitializeParams memory initializeParams) = abi.decode(_data, (QVBaseStrategy.InitializeParams));
        __QVBaseStrategy_init(_poolId, initializeParams);
        emit Initialized(_poolId, _data);
    }

    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // for coverage reasons
        if (_hasVoiceCreditsLeft(0, 0)) {
            _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
        }
    }
}
